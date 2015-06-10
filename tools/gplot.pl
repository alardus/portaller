#!/usr/bin/perl
###################################################################
#
# Name:	gplot.pl
#
# Description:
#   A "front-end" for gnuplot which tries to simplify the choice
#   of lines, colors etc. Input usually comes via a file,
#   but a model file can be provided too.
#
# ChangeLog:
#   $Log: gplot.pl,v $
#   Revision 1.11  2012-07-03 11:43:17  tpg
#   Changes from Sean O'Boyle <seanoboyle@gmail.com> -set string
#
#   Revision 1.10  2012-07-03 09:33:27  tpg
#   Changes from Jengwei Pan <jengwei@gmail.com> -interactive -splot -mplot RxC
#
#   Revision 1.9  2012-07-03 08:48:21  tpg
#   gnuplot 4.4 changed 'set data style lines' to 'set style data lines'
#
#   Revision 1.8  2008-01-23 17:52:27  tpg
#   Add verbose flag
#
#   Revision 1.7  2007/01/08 15:10:00  tpg
#   Allow one to plot more than 4 sets of data
#
#   Revision 1.6  2005/12/15 16:20:34  tpg
#   Add support for jpg
#
#   Revision 1.5  2005/12/15 16:04:34  tpg
#   Convert to use gnuplot 4.0
#
#   Revision 1.4  2005/02/16 17:24:37  tpg
#   Option is showgnuplot, not show
#
#   Revision 1.3  2005/01/14 18:24:41  tpg
#   Added option '-style' so you can make barcharts with ease
#   Added option '-dateformat' so you can plot things over time
#   Added support for '-type eps'
#   Added support for '-onecolumn', data with only one column of data
#
#   Revision 1.2  2003/12/22 17:09:24  tpg
#   Correct typos in the documenation
#   Correct -name so it gets reset each time
#
#   Revision 1.1  2003/12/19 20:04:42  tpg
#   Initial coding
#
# Thanks to these Contributors:
#   Sean O'Boyle <seanoboyle@gmail.com>
#   Jengwei Pan <jengwei@gmail.com>
#
# Copyright (C) 2003-2006 Terry Gliedt, University of Michigan
#
# This is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; See http://www.gnu.org/copyleft/gpl.html
###################################################################
use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use File::Temp qw/ tempfile tempdir /;

my($me, $mepath, $mesuffix) = fileparse($0, '.pl');
(my $version = '$Revision: 1.11 $ ') =~ tr/[0-9].//cd;
#   GNUPLOT has numerical values for linetype and pointtype
#   rather than using words that a person might possibly
#   remember.
#
#   In the surprise of the year, I discover that the POINTTYPES
#   VARY BY THE OUTPUT TERMINAL. Who could have imagined it?
#
#   Postscript supports dozens of pointtypes:
#            1 (+) 2 (X) 3 (*)
#            4 (box) 5 (filledbox)
#            6 (circle) 7 (filledcircle)
#            8 (uptriangle) 9 (filleduptriangle)
#           10 (downtriangle) 11 (filleddowntriangle)
#           12 (diamond) 13 (filleddiamond)
#           14 (pentagon) 15 (filledpentagon)
#           16 (circle node) 17-31 (various partially filled circle nodes)
#           32 (box node) 13-47 (various partially filled box nodes)
#           48 (diamond node) 49-63 (various partially filled diamond nodes)
#
#   Graphic outputs (X, png, pbm and jpg) only support
#            1 (diamond)
#            2 (plus)
#            3 (box)
#            4 (X)
#            5 (uptriangle)
#            6 (asterisk)

#   Valid values for various options
my %checktype = (xwin => 1, ps => 1, eps => 1, png => 1, pbm => 1, jpg => 1);
my %checkcolor = (red => 1, green => 2, blue => 3, magenta => 4,
    cyan => 5, yellow => 6, black => 7, orange => 8 );
my %checkpoint = ();
my %checkpoint_ps = (plus => 1, xx => 2, asterisk => 3,
    box => 4, filledbox => 5,
    circle => 6, filledcircle => 7,
    uptriangle => 8, filleduptriangle => 9,
    downtriangle => 10, filleddowntriangle => 11,
    diamond => 12, filleddiamond => 13,
    pentagon => 14, filledpentagon => 15,
);
my %checkpoint_notps = (diamond => 1, xx => 10, asterisk => 6,
    box => 3, plus => 2, uptriangle => 5,
);

#   Use this to put arbitrary text annotations in place
#set label "xxxxx %XLABEL%" at 50,1.5 right rotate font "%FONT%,6"
my $GNUCMDS = <<EOF;
#   GPLOT.PL pseudo commands for GNUPLOT
IF TYPE eq ps   set terminal postscript landscape color
IF TYPE eq eps  set terminal postscript eps color
IF TYPE eq jpg  set terminal jpeg
IF TYPE eq png  set terminal png
IF TYPE eq pbm  set terminal pbm
IF TYPE ne xwin set output "%OUTFILE%"
set xlabel "%XLABEL%" font "%FONT%,%FONTSIZE%"
set ylabel "%YLABEL%" font "%FONT%,%FONTSIZE%"
set autoscale
set style data lines
set border 3
set xtics border nomirror
set ytics border nomirror
set origin 0.0,0.0
set title "%TITLE%" font "%TFONT%,%TFONTSIZE%"
EOF

my $GNULS = "set style line %s lt &COLOR& lw %THICKNESS% pt &POINT& ps %POINTSIZE%";
my $GNUP  = " '%INFILE%' using %USING% title '%NAME%' with %STYLE% linestyle %s";

#--------------------------------------------------------------
#   Initialization - Sort out the options and parameters
#--------------------------------------------------------------
#   Set a mess of reasonable defaults
my %opts = (type => 'xwin', outfile => '/tmp/gplot.%TYPE%',
    pointsize => '0.65', color => 'red',
    point => 'uptriangle', thickness => 1,
    xlabel => 'X', ylabel => 'Y',
    title => 'No title provided', using => '1:2',
    style => 'linespoints',
    required_version => '4.4',      # GNUPLOT must be at this version
);
my @plotoptions = ('pointsize=s', 'color=s', 'point=s',
        'thickness=n', 'name=s', 'using=s', 'style=s');

#   Require_order set so one can specify @plotoptions for each
#   file to be plotted.
Getopt::Long::Configure('require_order');

#   First time we have a mess of options that pertain to everything
#   Subsequent iterations can only take a few options for each plot cmd
Getopt::Long::GetOptions( \%opts, 'help', 'showgnuplot', 'type=s', 'outfile=s',
    'plotcmds=s', 'xlabel=s', 'ylabel=s', 'title=s', 'dateformat=s',
    'font=s', 'fontsize=i', 'tfont=s', 'tfontsize=i', 'onecolumn', 'verbose',
    'interactive', 'mplot=s', 'splot', 'set=s', @plotoptions
    ) || die "Failed to parse options\n";

#   Simple help if requested
if ($opts{help} || $#ARGV < 0) {
    print STDERR "$me$mesuffix [options] indata.. indataN\n" .
        "Version $version which requires GNUPLOT $opts{required_version}\n" .
        "This is a smart frontend for gnuplot.\n" .
        "\nValid -type values: " .
        join(', ', sort keys %checktype) . "\n" .
        "\nValid -color values: " .
        join(', ', sort keys %checkcolor) . "\n" .
        "\nValid POSTSCRIPT -point values: " .
        join(', ', sort keys %checkpoint_ps) . "\n" .
        "\nValid non-POSTSCRIPT -point values: " .
        join(', ', sort keys %checkpoint_notps) . "\n" .
        "\nMore details available by entering:  perldoc $0\n\n";
    if ($opts{help}) { system("perldoc $0"); }
    exit 6;
}

#   Force default values and check options
if ($opts{type} eq 'jpeg') { $opts{type} = 'jpg'; }
if (! exists($checktype{$opts{type}})) { die "Invalid plot type '$opts{type}'\n"; }
if ($opts{type} eq 'ps' || $opts{type} eq 'eps') { %checkpoint = %checkpoint_ps; }
else { %checkpoint = %checkpoint_notps; }
if ($opts{font} && ! $opts{fontsize}) { $opts{fontsize} = 12; }
if ($opts{tfont} && ! $opts{tfontsize}) { $opts{tfontsize} = 14; }
if (exists($opts{point}) && (! exists($checkpoint{$opts{point}}))) {
    die "Invalid plot -point '$opts{point}'.\n" .
        "Remember, -point values differ based on -type.\n";
}
if (exists($opts{color}) && (! exists($checkcolor{$opts{color}}))) {
    die "Invalid plot -color '$opts{color}'\n";
}

#   Check version of gnuplot
$_ = `gnuplot --version`;
chomp();
if (/gnuplot (\d+\.\d+)/) {
    if ($1 < $opts{required_version}) {
        warn "Your GNUPLOT is '$_', but I require '$opts{required_version}'.  Continuing\n";
    }
}
else { warn "I don't think you have gnuplot installed. Contining\n"; }

#   Correct the output filename
$opts{outfile} =~ s/%TYPE%/$opts{type}/;

#--------------------------------------------------------------
#   Create input GNUPLOT file or use one provided
#--------------------------------------------------------------
my $gnuplotcmds = $GNUCMDS;

#   Add in dateformat support
if ($opts{dateformat}) {
    $gnuplotcmds .= "set xdata time\n" .
        "set timefmt \"$opts{dateformat}\"\n" .
        "set format x \"$opts{dateformat}\"\n";
}

#   Add in user gnuplot commands
if ($opts{plotcmds}) {
    open (IN, $opts{plotcmds}) ||
        die "Unable to open input file of GNUPLOT commands '$opts{plotcmds}': $!\n";
    $gnuplotcmds = "# NOTE: Cmds read from '$opts{plotcmds}'\n";
    while(<IN>) {                   # Suck in file provided. Clean out DOSisms
        chomp();
        if (/\r$/) { chop(); }
        $gnuplotcmds .= $_ . "\n";
    }
    close(IN);
}

#   If fonts were no provided, remove font specification in gnuplot commands
if (! $opts{font})  { $gnuplotcmds =~ s/font\s+\"%FONT%,%FONTSIZE%\"//g; }
if (! $opts{tfont}) { $gnuplotcmds =~ s/font\s+\"%TFONT%,%TFONTSIZE%\"//g; }

$gnuplotcmds = DoDefaults($gnuplotcmds);        # Convert &key&
if ($opts{set}) { $gnuplotcmds .= "set $opts{set}\n"; }     # From SOB

#
#   Calculate mplot values
#   Code originally from JWP in March 2011
#
my $mplotindex = 0;
my @mplotset_origin_array = ();
my ($mplotset_size, $mplot_total);
if ($opts{mplot}) {
    if ($opts{mplot} !~ /^(\d+)[xX](\d+)$/) {
        die "Invalid -mplot format '$opts{mplot}', should be rowXcolumn\n";
    }
    my ($row, $column) = ($1, $2);
    if ($row <= 0 || $column <= 0) {
        die "Invalid -mplot format '$opts{mplot}', row and column must be > 0\n";
    }
    $mplot_total =$row * $column;
    my $r_unit = sprintf ("%.2f", 1/$row);
    my $c_unit = sprintf ("%.2f", 1/$column);
    $mplotset_size = sprintf("set size %s, %s \n", $r_unit, $c_unit);
    my $i = 0;
    for (my $r=0; $r<$row; $r++) {
        for (my $c=0; $c<$column; $c++) {
            $mplotset_origin_array[$i++] = ($r_unit*$r) . ',' . ($c_unit*$c);
        }
    }
    $gnuplotcmds .= "set multiplot\n";
}

#--------------------------------------------------------------
#   For each input file provided, generate a plot
#   Each file can have its own set of options, so the cmd could be
#       plot.pl -color red  -name run1 1.data \
#               -color blue -name run2 2.data
#--------------------------------------------------------------
my $n = 10;
my @plotcmds = ();
my @temps = ();
while(@ARGV) {
    #   Take additional options
    Getopt::Long::GetOptions( \%opts, @plotoptions) ||
        die "Failed to parse options\n";
    $opts{infile} = shift @ARGV;
    if (! $opts{infile}) { die "Invalid syntax, no input data to plot found\n"; }
    if (! $opts{name}) { $opts{name} = basename($opts{infile}); }

    #   If asked for, convert this data into two column mode
    if ($opts{onecolumn}) {
        $opts{infile} = OneColumn($opts{infile});
        push @temps, $opts{infile};
    }
    my $plotit = $GNULS;
    $plotit =~ s/%s/$n/;
    $plotit = DoDefaults($plotit);
    $plotit = DoSubst($plotit);             # Convert %key%
    $gnuplotcmds .= $plotit;
    $plotit = $GNUP;
    $plotit =~ s/%s/$n/;
    $plotit = DoDefaults($plotit);
    $plotit = DoSubst($plotit);             # Convert %key%
    chomp($plotit);                         # Remove \n from DoSubst
    push @plotcmds,$plotit;
    $opts{color} = NextColor($opts{color});
    $opts{point} = NextPoint($opts{point});
    delete($opts{name});
    $n++;

    #   Handle mplot here  (thanks to JWP)
    if ($opts{mplot}) {
        $gnuplotcmds .= $mplotset_size;     # Calculated above
        $gnuplotcmds .= sprintf("set origin %s \n", $mplotset_origin_array[$mplotindex++]);
        if ($opts{splot}) { $gnuplotcmds .= 'splot' . $plotit . "\n"; }
        else { $gnuplotcmds .= 'plot'  . $plotit . "\n"; }
        if ($mplotindex == $mplot_total) { last; }
    }
}
$gnuplotcmds = DoSubst($gnuplotcmds);       # Convert %key%

#   Complete gnuplot commands   Handle mplot, splot and interactive from JWP
if ($opts{mplot}) { $gnuplotcmds .= "\nunset multiplot \n"; }
else {
    if ($opts{splot}) { $gnuplotcmds .= 'splot' . join(",  \\\n", @plotcmds); }
    else { $gnuplotcmds .= 'plot'  . join(",  \\\n", @plotcmds); }
}
if ($opts{interactive}) { $gnuplotcmds .= "\npause -1 'You asked for interactive'\n"; }

#   Create GNUPLOT input and invoke it
my $cmdsfile = "/tmp/$opts{type}.gnuplot";  # Gnuplot commands file
open(OUT,">$cmdsfile") ||
    die "Unable to create file '$cmdsfile': $!\n";
print OUT $gnuplotcmds . "\n";
if ($opts{showgnuplot}) { print $gnuplotcmds . "\n"; }
close(OUT);

#   Actually invoke gnuplot
push @temps,$cmdsfile,"$cmdsfile.err";
my $cmd = "gnuplot -persist $cmdsfile";
my $rc = system("$cmd > $cmdsfile.err 2>&1");
if ($opts{verbose}) {
    print "Cmd=$cmd\nFollowing temporary files not deleted: " .
        "$cmdsfile.err " . join(' ', @temps) . "\n";
}
else {
    if ($rc == 0) { unlink(@temps,"$cmdsfile.err"); }
}
if ($rc != 0) {
    system("cat $cmdsfile.err");
    die "\nGnuplot failed.  Cmd='$cmd'  Errors in '$cmdsfile.err'\n";
}

#--------------------------------------------------------------
#   All done -- clean up
#--------------------------------------------------------------
if ($opts{type} ne 'xwin') {
    print "Created GUPLOT output in '$opts{outfile}'\n";
}
exit 0;

#==================================================================
# Subroutine:
#   OneColumn
#
# Description:
#   Convert a one column file into two columns
#
# Arguments:
#   f - file of data to convert
#
# Return:
#   path to temp file created
#
#==================================================================
sub OneColumn {
    my ($f) = @_;

    open(ONEIN,$f) ||
        die "Unable to read file '$f;: $!\n";
    print "Converting '$f' into two columns of data\n";
    my ($fh, $newf) = tempfile();
    my $n = 0;
    while(<ONEIN>) { print $fh "$n $_"; $n++; }
    close(ONEIN);
    close($fh);
    return $newf;
}

#==================================================================
# Subroutine:
#   DoDefaults
#
# Description:
#   Substitute for &string& in a string provided
#
# Arguments:
#   str - string with possible keywords
#
# Return:
#   new string
#
#==================================================================
sub DoDefaults {
    my ($str) = @_;

    $str =~ s/&TYPE&/\%$opts{type}\%/gm;
    $str =~ s/&COLOR&/\%$opts{color}\%/gm;
    $str =~ s/&POINT&/\%$opts{point}\%/gm;
    return $str;
}

#==================================================================
# Subroutine:
#   DoSubst
#
# Description:
#   Substitute for %string% in a string provided
#
# Arguments:
#   str - string with possible keywords
#
# Return:
#   new string
#
#==================================================================
sub DoSubst {
    my ($str) = @_;

    my @lines = split("\n", $str);
    foreach my $l (@lines) {
        if ($l =~ /^\s*$/) { next; }
        #   IF TYPE eq XX cmd
        if ($l =~ /^IF\s+(\w+)\s+(eq|ne)\s+(\w+)\s+(.+)/) {
            my ($key, $op, $val, $cmd) = ($1, $2, $3, $4);
            $key = lc($key);                # TYPE -> type
            if (! exists($opts{$key})) {
                die "Invalid key '$key' in IF statement: $l";
            }
            if ($op eq 'eq') {
                if ($opts{$key} eq $val) { $l = $cmd . "\n"; }  # Remove IF clause
                else { $l = "## $l"; }      # Disable IF clause
            }
            elsif ($op eq 'ne') {
                if ($opts{$key} ne $val) { $l = $cmd . "\n"; }  # Remove IF clause
                else { $l = "## $l"; }      # Disable IF clause
            }
            else { die "Invalid operator '$op' in IF statement: $l\n"; }
        }
        if ($l =~ /^#/) { next; }
        #   Change %XXX% into proper values now
        while ($l =~ /(.+)%(\w{2,})%(.*)/) {
            my ($start, $key, $rest) = ($1, $2, $3);
            my $lckey = lc($key);
            my $uckey = uc($key);
            my $val = $opts{$lckey};
            if (! defined($val)) { $val = $checktype{$lckey}; }
            if (! defined($val)) { $val = $checkcolor{$lckey}; }
            if (! defined($val)) { $val = $checkpoint{$lckey}; }
            if (! defined($val)) {
                die "Unknown keyword '%$key%' in GNUPLOT line: $l\n";
            }
            $l = $start . $val . $rest;     # Redefine the line
        }
    }
    return join("\n", @lines) . "\n";
}

#==================================================================
# Subroutine:
#   NextColor
#
# Description:
#   Based on the existing color, pick another one.
#
# Arguments:
#   c - color
#
# Return:
#   new color
#
#==================================================================
sub NextColor {
    my ($c) = @_;

    #   Force our own order so we get better contrast
    my @colororder = qw(red blue black cyan green orange magenta yellow);
    foreach (my $i=0; $i<$#colororder; $i++) {
        if ($colororder[$i] ne $c) { next; }
        #   Found our color, get next and return
        $i++;
        if ($i >= $#colororder) { $i = 0; }
        return $colororder[$i];
    }
    return $colororder[0];
}

#==================================================================
# Subroutine:
#   NextPoint
#
# Description:
#   Based on the existing linepoint, pick another one.
#
# Arguments:
#   p - point
#
# Return:
#   new point
#
#==================================================================
sub NextPoint {
    my ($p) = @_;

    my @pointorder = %checkpoint;
    foreach (my $i=0; $i<$#pointorder; $i+=2) {
        if ($pointorder[$i] ne $p) { next; }
        #   Found our point, get next and return
        $i += 2;
        if ($i >= $#pointorder) { $i = 0; }
        return $pointorder[$i];
    }
    return $pointorder[0];
}


#==================================================================
#   Perldoc Documentation
#   pod2html --infile gplot.pl --outfile web/man.html; rm -f pod2htm?.tmp
#==================================================================
__END__

=head1 NAME

gplot.pl - A smart frontend for gnuplot 4.4 and above

=head1 SYNOPSIS

    gplot.pl my.data

    gplot.pl -color blue my.data

    gplot.pl -title "My results"  my.data
    
    gplot.pl -interactive -color red 1a.data -color green 2a.data

    gplot.pl -type jpg -title "My results"  my.data

    gplot.pl -title "Our results"  \
        -color red my.data   -color blue your.data

    gplot.pl -splot -mplot 5x2 -title foobar  \
      -using 1:2:3 3d_1.dat -using 1:2:3 3d_6.dat \
      -using 1:2:3 3d_2.dat -using 1:2:3 3d_7.dat \
      -using 1:2:3 3d_3.dat -using 1:2:3 3d_8.dat \
      -using 1:2:3 3d_4.dat -using 1:2:3 3d_9.dat \
      -using 1:2:3 3d_5.dat -using 1:2:3 3d_10.dat  

=head1 DESCRIPTION

This program provides a convenient front-end for gnuplot 4.0.
Previous versions of gnuplot have a different syntax and you should
be using gplot.pl version 1.1 for these.
It accepts a large set of options to generate a single plot
of one or more sets of data (overlaid as necessary).
The X and Y axis will be scaled automatically.

The options are provide in two categories. Most options
apply to the entire plot (e.g. title) whereas a smaller
set can be entered multiple times so that certain values
can be set for each plot (e.g. color for each plot).
This may require careful reading of the options listed below.

This adds no new functionality to gnuplot, but makes it
easier to generate GNUPLOT input.
Gnuplot input can be very confusing when trying to assign useful
colors (linetypes) or linepoints since it uses numeric values
that vary based on the output device. gplot.pl allows you to set
various attributes with English words like 'red' and 'triangle',
thereby simplifying the interaction with gnuplot.
This program only supports Postscript, PBM, PNG, JPG and 'X" output.

Additional information on using gnuplot is available at

    http://www.gnuplot.info/
    http://www.duke.edu/~hpgavin/gnuplot.html

=head1 GLOBAL OPTIONS

These options apply to all data that is plotted. You may not
usefully specify these more than once.

=over 4

=item B<-font string>

Specifies the font used for -xlabel and -ylabel.
This uses the default for your gplot and terminal.
This setting may not be applied for all -type settings,
but *is* applied for Postscript.

=item B<-fontsize N>

Specifies the fontsize used for -xlabel and -ylabel.
This uses the default for your gplot and terminal.
If you specify -font, this defaults to 12.
This setting may not be applied for all -type settings,
but *is* applied for Postscript.

=item B<-help>

Shows help for this command.

=item B<-interactive>

If specified, inserts a PAUSE command in the commands to GNUPLOT.

=item B<-mplot ROWxCOLUMN>

Enables multiplot in GNUPLOT. ROW and COLUMN must be positive integers.
You might try this:
  gplot.pl -inter -splot -mplot 5x2 -title foobar  \
    -using 1:2:3 3d_1.dat -using 1:2:3 3d_6.dat \
    -using 1:2:3 3d_2.dat -using 1:2:3 3d_7.dat \
    -using 1:2:3 3d_3.dat -using 1:2:3 3d_8.dat \
    -using 1:2:3 3d_4.dat -using 1:2:3 3d_9.dat \
    -using 1:2:3 3d_5.dat -using 1:2:3 3d_10.dat  

=item B<-onecolumn>

If specified, this indicates all of the datafiles to be plotted
have only one column of Y data.
We will copy the data creating two columns of data.
The x axis begins with 0 and increments by 1.
Temporary input files are deleted when the plot is finished.

=item B<-outfile file>

Specifies the name of the output file to be created.
The default is '/tmp/gplot.' followed by the -type of plot
(e.g. '-type ps' creates '/tmp/gplot.ps').

=item B<-plotcmds file>

Specifies that the input commands should be taken from 'file'.
If not provided a default set are used.
Read "PSEUDO COMMANDS IN YOUR OWN GNUPLOT FILE" for more details
on this option.

=item B<-set string>

Allows you to add a set command in the GNUPLOT commands with
a simple option.
This could also be done with the option B<-plotcmds>.
For instance you might want to just add B<set logscale y>
in the GNUPLOT command stream with B<-set 'logscale y'>.

=item B<-showgnuplot>

If set, this will cause the GNUPLOT commands to be written to STDOUT.
This is useful if you want to capture the output from gplot.pl
and then tailor this to add your own gnuplot commands.
See also the -plotcmds option.

=item B<-splot>

If set, this will allow GNUPLOT to generate 3D or 4D plots.
The default (plot) can only generate 2D plots
(e.g. gplot.pl -interactive -splot -using 1:2:4 4d.dat).

=item B<-tfont string>

Specifies the font used for -title.
This uses the default for your gplot and terminal.
This setting may not be applied for all -type settings,
but *is* applied for Postscript.

=item B<-tfontsize N>

Specifies the fontsize used for -title.
This uses the default for your gplot and terminal.
If you specify -font, this defaults to 14.
This setting may not be applied for all -type settings,
but *is* applied for Postscript.

=item B<-title string>

Specifies the title shown at the top of the page.
If 'string' is a null string, no title is displayed.

=item B<-type xwin|jpg|jpeg|png|pbm|ps|eps>

Specifies the types of output plots are to be created. Values may be
'xwin' (generate a plot and show it on the screen),
'png', 'pbm', 'jpg' or 'jpeg' (create a graphic),
'eps' (create encapsulated postscript),
or 'ps' (create a postscript file).
The default is 'xwin'.

If you create a Postscript file, you can usefully print
it with a command like:

    lpr my.ps

You may convert a Postscript file to a PDF with:

    ps2pdf14 my.ps my.pdf

You may create a JPEG file by first creating a PBM file and then:

    cjpeg  my.pbm > my.jpg

=item B<-xlabel string>

Specifies the X label of the plot.
Just how this is displayed will vary based on -type.
If 'string' is a null string, no label is displayed.

=item B<-ylabel string>

Specifies the Y label of the plot.
Just how this is displayed will vary based on -type.
Postscript output will have the label written vertically.
If 'string' is a null string, no label is displayed.

=back


=head1 OPTIONS FOR EACH FILE TO PLOT

These options may be specified more than once so that you may
control the appearance of each data that is plotted.
For example if you have three files of data to plot and want
them plotted with different colors, you might do:

  gplot.pl -color red 1.data -color blue 2.data -color green 3.data

=over 4

=item B<-dateformat format>

Specifies the X coordinate data are dates in the format 'format'.
'Format' should consist of a series of %-keys describing the format of the data.
For instance '%y%m%d' says the data conists of a TWO digit year
followed by a two digit month and a two digit day.
"%m/%d/%y" is month, day and year separated by a slash.
If you want a barchart, include the option '-style impulses'.

=item B<-color string>

Specifies the color the data will be plotted in.
When generating a Postscript file, the lines will not only be
in the color you specify, but the lines themselves are each
different so you can print the Postscript file to a non-color
printer and still distinguish the lines.
Specify 'gplot.pl' to see a list of colors supported.

=item B<-name string>

Specifies the label for this plot. This shows in the legend
showing the line color and point.

=item B<-point string>

Specifies the shape of the datapoint used for this plot.
For no reason that is obvious, gnuplot has DIFFERENT SETS OF POINTS
based on value of the -type option.
Postscript has a large set of supported shapes (circles,
boxes, fillcircles, filldowntriangles to name a few).
The other types of output have only six supported shapes.
Specify 'gplot.pl' (with no parameters) to see a list of points supported.

=item B<-pointsize F>

Specifies the size of the datapoint used for this plot.
See the -point option.
This is a floating point number. Useful numbers seem to be
about one-half. Larger values will create large and probably
uninteresting datapoints on the plot.

=item B<-style name>

Specifies the 'style' to be used for this plot. This value
depends on your version of gnuplot, but includes at least
the following: boxes, dots, impulses (for simple barcharts),
lines, linespoints (the default), points, steps and vector.

=item B<-using X:Y>

Specifies the input columns for the X and Y columns to be printed.
Note that a colon separates the two values.
A value like '-using 4:2' means that the input data has at least
four columns and the fourth column is the X value and the second
is the Y value.
The default is '-using 1:2'.

=item B<-thickness N>

Specifies the thickness of the line used for this plot.
The default is 1. Values over two seem uninteresting unless
you specify '-style impulses' to produce simple barcharts.

=back


=head1 PARAMETERS

=over 4

=item B<infile1 ... infileN>

Specifies the name of the files to be plotted.
If more than one is provided, the plots are overlaid
and a new -color and -point will be chosen.
You may (and should) specify your own -color and -point options
for each plot.

=back


=head1 PSEUDO COMMANDS IN YOUR OWN GNUPLOT FILE

It is possible for you to provide your own file of gnuplot commands
and still take advantage of gplot.pl.
The -showgnuplot command will print to STDOUT the input file
provided to gnuplot. This is a good place to start.
For example the command 'gplot.pl 1a.data' creates this file:

    #   GPLOT.PL pseudo commands for GNUPLOT
    set xlabel "X" font "Helvetica,12"
    set ylabel "Y" font "Helvetica,12"
    set multiplot
    set autoscale
    set data style lines
    set border 3
    set xtics border nomirror
    set ytics border nomirror
    set origin 0.0,0.0
    set title "No title provided" font "Helvetica,14"
    set style line 10 lt 1 lw 1 pt 10 ps 2.0
    plot '1a.data' using 1:2 title '1a.data' with linespoints linestyle 10

Most of this looks pretty straightforward - except for the 'style line'
(especially) and plot lines. gplot.pl uses meaningful words as
values for -color and -point
and converts these to the numbers you see above.

You can provide your own gnuplot input and have gplot.pl make the
substitution that it normally does. Specify the file of
gnuplot commands with the -plotcmds option.
If you put keywords in this file, gplot.pl will replace the keywords
with the correct values for -color etc.
The only thing to know are the details of the keywords.
The default 'file' of gnuplot commands in gplot.pl looks like:

    #   GPLOT.PL pseudo commands for GNUPLOT
    IF TYPE eq ps   set terminal postscript landscape color
    IF TYPE eq eps  set terminal postscript eps color
    IF TYPE eq jpg  set terminal jpeg
    IF TYPE eq png  set terminal png
    IF TYPE eq pbm  set terminal pbm
    IF TYPE ne xwin set output "%OUTFILE%"
    set xlabel "%XLABEL%" font "%FONT%,%FONTSIZE%"
    set ylabel "%YLABEL%" font "%FONT%,%FONTSIZE%"
    set multiplot
    set autoscale
    set data style lines
    set border 3
    set xtics border nomirror
    set ytics border nomirror
    set origin 0.0,0.0
    set title "%TITLE%" font "%TFONT%,%TFONTSIZE%"

Comparing this file with the final input to gnuplot, you will
immediately notice the 'IF TYPE' and '%key%' strings.
The 'IF TYPE' strings provide a very simple logic capability
so we can generate the proper 'set terminal' commands based
on the -type option.

Strings of the form '%key%' are keywords substituted directly
from the various options to gplot.pl (%XLABEL% is replaced by
the value for -xlabel etc.).

For each input file, gplot.pl adds a 'style line' command like this:

    set style line %s lt &COLOR& lw %THICKNESS% pt &POINT& ps %POINTSIZE%

This has the same '%key%' strings which are changed as described
above. You'll also notice '&key&' strings which go through a similar
substitution, only twice. For instance '&COLOR&' is replaced by the value
for -color which might be 'red' (actually it becomes '%red%').
This value is then replaced as above, converting '%red%' into '1'.
Note that '%s' is replaced with a number that gets incremented for
each input file.

A second string is built for each input file and looks like this:

    '%INFILE%' using %USING% title '%NAME%' with linespoints linestyle %s

This string follows the same substitution conventions shown above.

=head1 -PLOTCMDS EXAMPLE

A good start is the internal form used by gplot.pl itself
(you may, of course, do anything that gnuplot will be happy with)
and then add your own special commands.
You may want to check out the URLs mentioned at the top of this help file.
In this example, we start with the gplot.pl default file
and add a few lines as noted in the comments:

    #   GPLOT.PL pseudo commands for GNUPLOT
    IF TYPE eq ps   set terminal postscript landscape color
    IF TYPE eq eps  set terminal postscript eps color
    IF TYPE eq jpg  set terminal jpeg
    IF TYPE eq png  set terminal png
    IF TYPE eq pbm  set terminal pbm
    IF TYPE ne xwin set output "%OUTFILE%"
    set xlabel "%XLABEL%" font "%FONT%,%FONTSIZE%"
    set ylabel "%YLABEL%" font "%FONT%,%FONTSIZE%"
    set multiplot
    set autoscale
    set data style lines
    set border 3
    set xtics border nomirror
    set ytics border nomirror
    set origin 0.0,0.0
    set title "%TITLE%" font "%TFONT%,%TFONTSIZE%"
    #   Get rid of the legend
    set nokey
    #   Add a couple of comments to the plot
    set label "Peak" at 145,1.95
    set label "RH Point" at 170,0.95
    #   Put in tags vertically at 1.8, downwards
    set label "June 1990"  at 60,1.8 right rotate font "Helvetica,8"
    set label "May 1990"   at 50,1.8 right rotate font "Helvetica,8"
    set label "April 1990" at 40,1.8 right rotate font "Helvetica,8"

Generate plots with

    gplot.pl -type ps -plotcmds test.gnuplot -xlabel Contributions \
        -ylabel "Rate (cm/day)" -title "Annotated Example" 1a.data

If you use -type xwin (the default), the labels will be horizontal
and not vertical. Using another -type value will generate something
more meaningful.

Notice that the test.gnuplot file contained no linetype or plot
commands - gplot.pl generated them for you.


=head1 EXIT

If no fatal errors are detected, the program exits with a
return code of 0. Any error will set a non-zero return code.

=head1 AUTHOR

Written by Terry Gliedt I<E<lt>tpg@umich.eduE<gt>> in 2003-2012 and
is made available under terms of the GNU General Public License.

=cut

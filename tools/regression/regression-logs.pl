#!/usr/bin/perl

#~ Copyright (C) 2003, Rene Rivera.
#~ Use, modification and distribution is subject to the Boost Software
#~ License Version 1.0. (See accompanying file LICENSE-1.0 or
#~ http://www.boost.org/LICENSE-1.0)

use FileHandle;
use Time::Local;

# Get the whle percent value
#
sub percent_value
{
    my ($count,$total) = @_;
    return int (($count/$total)*100+0.5);
}

# Generate item html for the pass column.
#
sub result_info_pass
{
    my ($color,$pass,$warn,$fail) = @_;
    my $percent = 100-percent_value($fail,$pass+$warn+$fail);
    return "<font color=\"$color\"><font size=\"+1\">$percent%</font><br>($warn&nbsp;warnings)</font>";
}

# Generate item html for the fail column.
#
sub result_info_fail
{
    my ($color,$pass,$warn,$fail) = @_;
    my $percent = percent_value($fail,$pass+$warn+$fail);
    return "<font color=\"$color\"><font size=\"+1\">$percent%</font><br>($fail)</font>";
}

# Generate an age highlighted run date string.
# Use as: data_info(run-date-html)
#
sub date_info
{
    my %m = ('January',0,'February',1,'March',2,'April',3,'May',4,'June',5,
        'July',6,'August',7,'September',8,'October',9,'November',10,'December',11);
    my @d = split(/ |:/,$_[0]);
    my ($hour,$min,$sec,$day,$month,$year) = ($d[0],$d[1],$d[2],$d[4],$m{$d[5]},$d[6]);
    #print "<!-- $hour.$min.$sec.$day.$month.$year -->\n";
    my $test_t = timegm($sec,$min,$hour,$day,$month,$year);
    my $age = time-$test_t;
    my $age_days = $age/(60*60*24);
    #print "<!-- $age_days days old -->\n";
    my $age = "<font>";
    if ($age_days <= 2) { }
    elsif ($age_days <= 14) { $age = "<font color=\"#FF9900\">"; }
    else { $age = "<font color=\"#FF0000\">"; }
    return $age.$_[0]."</font>";
}

# Generate an age string based on the run date.
# Use as: age_info(run-date-html)
#
sub age_info
{
    my %m = ('January',0,'February',1,'March',2,'April',3,'May',4,'June',5,
        'July',6,'August',7,'September',8,'October',9,'November',10,'December',11);
    my @d = split(/ |:/,$_[0]);
    my ($hour,$min,$sec,$day,$month,$year) = ($d[0],$d[1],$d[2],$d[4],$m{$d[5]},$d[6]);
    #print "<!-- $hour.$min.$sec.$day.$month.$year -->\n";
    my $test_t = timegm($sec,$min,$hour,$day,$month,$year);
    my $age = time-$test_t;
    my $age_days = $age/(60*60*24);
    #print "<!-- $age_days days old -->\n";
    my $age = "<font>";
    if ($age_days <= 2) { }
    elsif ($age_days <= 14) { $age = "<font color=\"#FF9900\">"; }
    else { $age = "<font color=\"#FF0000\">"; }
    if ($age_days <= 1) { $age = $age."today"; }
    elsif ($age_days <= 2) { $age = $age."yesterday"; }
    elsif ($age_days < 14) { my $days = int $age_days; $age = $age.$days." days"; }
    elsif ($age_days < 7*8) { my $weeks = int $age_days/7; $age = $age.$weeks." weeks"; }
    else { my $months = int $age_days/28; $age = $age.$months." months"; }
    return $age."</font>";
}

#~ foreach my $k (sort keys %ENV)
#~ {
    #~ print "<!-- $k = $ENV{$k} -->\n";
#~ }
opendir LOGS, "$ENV{PWD}";
my @logs = grep /.*links[^.]*\.html$/, readdir LOGS;
closedir LOGS;
my @bgcolor = ( "bgcolor=\"#EEEEFF\"", "" );
my $row = 0;
print "<table>\n";
print "<tr>\n",
    "<th align=\"left\" bgcolor=\"#DDDDDD\">Platform</th>\n",
    "<th align=\"left\" bgcolor=\"#DDDDDD\">Run Date</th>\n",
    "<th align=\"left\" bgcolor=\"#DDDDDD\">Age</th>\n",
    "<th align=\"left\" bgcolor=\"#DDDDDD\">Compilers</th>\n",
    "<th align=\"left\" bgcolor=\"#DDDDDD\">Pass</th>\n",
    "<th align=\"left\" bgcolor=\"#DDDDDD\">Fail</th>\n",
    "</tr>\n";
foreach $l (sort { lc($a) cmp lc($b) } @logs)
{
    my $log = $l;
    $log =~ s/-links//s;
    my ($spec) = ($log =~ /cs-([^\.]+)/);
    my $fh = new FileHandle;
    if ($fh->open("<$ENV{PWD}/$log"))
    {
        my $content = join('',$fh->getlines());
        $fh->close;
        my ($status) = ($content =~ /(<h1>Compiler(.(?!<\/td>))+.)/si);
        my ($platform) = ($status =~ /Status: ([^<]+)/si);
        my ($run_date) = ($status =~ /Date:<\/b> ([^<]+)/si);
        $run_date =~ s/, /<br>/g;
        my ($compilers) = ($content =~ /Test Type<\/a><\/t[dh]>((.(?!<\/tr>))+.)/si);
        if ($compilers eq "") { next; }
        $compilers =~ s/-<br>//g;
        $compilers =~ s/<\/td>//g;
        my @compiler = ($compilers =~ /<td>(.*)$/gim);
        my $count = @compiler;
        my @results = ($content =~ /(>Pass<|>Warn<|>Fail<)/gi);
        my $test_count = (scalar @results)/$count;
        my @pass = map { 0 } (1..$count);
        my @warn = map { 0 } (1..$count);
        my @fail = map { 0 } (1..$count);
        my @total = map { 0 } (1..$count);
        for my $t (1..$test_count)
        {
            my @r = @results[(($t-1)*$count)..(($t-1)*$count+$count-1)];
            for my $c (1..$count)
            {
                if ($r[$c-1] =~ /Pass/i) { ++$pass[$c-1]; }
                elsif ($r[$c-1] =~ /Warn/i) { ++$warn[$c-1]; }
                elsif ($r[$c-1] =~ /Fail/i) { ++$fail[$c-1]; }
                ++$total[$c-1];
            }
        }
        for my $comp (1..(scalar @compiler))
        {
            my @lines = split(/<br>/,$compiler[$comp-1]);
            if (@lines > 2) { $compiler[$comp-1] = join(' ',@lines[0..(scalar @lines)-2])."<br>".$lines[(scalar @lines)-1]; }
        }
        print
            "<tr>\n",
            "<td rowspan=\"$count\" valign=\"top\"><font size=\"+1\">$platform</font><br>(<a href=\"./$log\">$spec</a>)</td>\n",
            "<td rowspan=\"$count\" valign=\"top\">",$run_date,"</td>\n",
            "<td rowspan=\"$count\" valign=\"top\">",age_info($run_date),"</td>\n",
            "<td valign=\"top\" ",$bgcolor[$row],">",$compiler[0],"</td>\n",
            "<td valign=\"top\" ",$bgcolor[$row],">",result_info_pass("#000000",$pass[0],$warn[0],$fail[0]),"</td>\n",
            "<td valign=\"top\" ",$bgcolor[$row],">",result_info_fail("#FF0000",$pass[0],$warn[0],$fail[0]),"</td>\n",
            "</tr>\n";
        $row = ($row+1)%2;
        foreach my $c (1..($count-1))
        {
            print
                "<tr>\n",
                "<td valign=\"top\" ",$bgcolor[$row],">",$compiler[$c],"</td>\n",
                "<td valign=\"top\" ",$bgcolor[$row],">",result_info_pass("#000000",$pass[$c],$warn[$c],$fail[$c]),"</td>\n",
                "<td valign=\"top\" ",$bgcolor[$row],">",result_info_fail("#FF0000",$pass[$c],$warn[$c],$fail[$c]),"</td>\n",
                "</tr>\n";
            $row = ($row+1)%2;
        }
        print
            "<tr>\n",
            "<td colspan=\"7\"><hr size=\"1\" noshade></td>\n",
            "</tr>\n";
    }
}
print "</table>\n";

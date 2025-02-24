#!/usr/bin/perl
use strict;
use Data::Dumper;
use File::Basename;

my %wisemapping = (
    "alienvault" => "alien-vault",
    "opendns" => "opendns-umbrella",
    "valueactions" => "value-actions",
    "fieldactions" => "field-actions",
    "emergingthreats" => "emerging-threats",
    "wiseproxy" => "wiseproxy"
);

# WISE
foreach my $file (glob '../wiseService/source.*.js') {
    # Extract the filename without extension
    my $filename = substr(basename($file, '.js'), 7);
    my $wise = `egrep -h 'getConfig\\(' ../wiseService/source.$filename.js`;

    next if ($filename eq "hodiredis" || $filename eq "wiseproxy");

    if ($wisemapping{$filename}) {
        $filename = $wisemapping{$filename};
    }

    if (! -f "../../arkimeweb/_data/wise/$filename.yml") {
        print "MISSING file: $filename\n";
        print "$wise\n";
        next;
    }

    foreach my $line (split("\n", $wise)) {
        my ($match) = $line =~ /getConfig\([^,]*, ["']([^"']*)["']/;

        my $output = `egrep  'key: $match' ../../arkimeweb/_data/wise/$filename.yml`;
        if ($output eq "") {
            print "MISSING key: $filename - $match}\n";
        }
    }
}

my %settings;
my $capture = `egrep -h 'arkime_config_(str|int|boolean|double).*"' ../capture/*.c ../capture/*/*.c ../capture/*/*/*.c`;
foreach my $line (split("\n", $capture)) {
    my ($match) = $line =~ /"([^"]*)"/;
    next if ($match =~ /^(nodeClass)$/);
    $settings{$match} = $line;
}

my $viewer = `egrep -h 'Config.get(\\(|Full|Array|ArrayFull)' ../viewer/*.js ../common/*.js ../parliament/*.js ../wiseService/*.js ../cont3xt/*.js ../cont3xt/integrations/*/*.js`;
foreach my $line (split("\n", $viewer)) {
    my ($match) = $line =~ /get[^"']*["']([^"']*)["']/;
    next if ($match =~ /^(default|s2sRegressionTests)$/);
    $settings{$match} = $line;

    #print "$match => $line\n";
}

delete $settings{'updateTime'}; # a wise fake setting
delete $settings{'user-setting-defaults'};
delete $settings{'Maxmind'};

foreach my $setting (keys (%settings)) {
    if ($setting =~ /[^0-9a-zA-Z_-]/) {
        print "***Not a real setting $setting\n";
        next;
    }

    my $output = `egrep  'key: $setting' ../../arkimeweb/_data/*/*`;
    if ($output eq "") {
        print "MISSING key: $setting - $settings{$setting}\n";
    }

    #    $output = `egrep  '( $setting\$|>$setting<|^$setting\\|)' ../../arkimeweb/settings.html ../../arkimeweb/_wiki/wise.md ../../arkimeweb/_data/settings/*`;
    #if ($output eq "") {
    #    print "MISSING $setting\n";
    #}
}

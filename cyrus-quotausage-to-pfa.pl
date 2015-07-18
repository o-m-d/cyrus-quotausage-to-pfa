#!/usr/bin/perl 

# Script for writing cyrus-imap mailboxes quota usage to PostfixAdmin database
#
# 2015-07-18 Created by Olexandr Davydenko <odavydenko@gmail.com>
# License: GPL v2
#
# Usage:
# Add to PostfixAdmin config.local.php options
#  $CONF['quota'] = 'YES';
#  $CONF['used_quotas'] = 'YES';
#  $CONF['new_quota_table'] = 'YES';
# Set up options
# Set up periodic execution of this script in crontab or EVENTS section of cyrus.conf

use strict;
use DBI;
use Cyrus::IMAP::Admin;
require '/usr/local/www/postfixadmin/ADDITIONS/cyrus/cyrus.conf';
use vars qw($cyrus_user $cyrus_password $cyrus_host);

my %opts;

my $unixhierarchyprefix = "user."; # set it properly
my $db_password = '*****';
my $db_user_name = 'postfix';
my $dsn = 'DBI:mysql:postfix:localhost';
my $dbh = DBI->connect($dsn, $db_user_name, $db_password, {'RaiseError' => 1});

my $client = Cyrus::IMAP::Admin->new($cyrus_host);
die_on_error($client);

$opts{-user} = $cyrus_user;
$opts{-password} = $cyrus_password;

$client->authenticate(%opts);
die_on_error($client);

my $sth = $dbh->prepare("SELECT * FROM mailbox;");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
	(my $mboxroot, my %mboxquota) = $client->quotaroot($unixhierarchyprefix.$ref->{'username'});
	$dbh->do("INSERT INTO quota2 (username, bytes) VALUES (?, ?) ON DUPLICATE KEY UPDATE bytes = VALUES(bytes);", undef, $ref->{'username'}, $mboxquota{'STORAGE'}[0]);
}
$sth->finish();

$dbh->disconnect();

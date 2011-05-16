#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin::libs;
use XML::FeedPP;
use Git::Repository 'File';
use DietWiki;
use DietWiki::Entry;
use Path::Class qw/dir/;
use URI::tag;
use Time::Piece;

my $c = DietWiki->bootstrap;
#my $domain = 'dietcolumn.songmu.dotcloud.com';
my $domain = $c->config->{FQDN};
my $url_root = "http://$domain/";

my $target_dir = 'tmpl/mkdn/';
my $git_dir = $c->base_dir .'/.git';
my $repo = Git::Repository->new( git_dir => $git_dir );

my $mkdn_dir = dir($c->base_dir, $target_dir);

my @entries;
for my $file ( grep { -f -r $_ && $_ =~ /\.mkdn$/ } $mkdn_dir->children ){
    my $git_file = $repo->file($target_dir . $file->basename)->use_time_piece;
    my $entry = DietWiki::Entry->new($file);
    my $entry_path = $file->basename;
    $entry_path =~ s/\.mkdn$//;
    $entry_path = "entry/$entry_path";
    my $url = $url_root .$entry_path;
    my $tag_uri = URI->new('tag:');
    $tag_uri->authority($domain);
    $tag_uri->date($git_file->last_modified_at->strftime('%Y-%m-%d'));
    $tag_uri->specific(join('-',split(m{/},$entry_path)));

    push @entries, {
        title       => $entry->title,
        description => \$entry->body_as_html, #pass scalar ref for CDATA
        pubDate     => $git_file->last_modified_at->epoch,
        author      => $git_file->created_by,
        guid        => $tag_uri->as_string,
        published   => $git_file->created_at->datetime,
        link        => $url,
    } unless $entry->headers('draft');
}

my $gm_now = gmtime;
my $tag_uri = URI->new('tag:');
$tag_uri->authority($domain);
$tag_uri->date($gm_now->strftime('%Y-%m-%d'));
my $feed = XML::FeedPP::Atom::Atom10->new(
    link    => $url_root,
    author  => 'Masayuki Matsuki',
    title   => 'いいか、覚えておくといい。ダイエットには王道しかない',
    pubDate => $gm_now->epoch,
    id      => $tag_uri->as_string,
);

$feed->add_item(%$_) for @entries;
$feed->sort_item;

open my $xml_fh,'>:utf8',$c->base_dir . '/htdocs/atom.xml' or die "$!";
print $xml_fh $feed->to_string;


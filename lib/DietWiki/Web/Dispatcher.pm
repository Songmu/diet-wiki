package DietWiki::Web::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::Lite;
use File::Spec;
use Path::Class;
use Time::Piece;
use DietWiki::Entry;

any '/' => sub {
    shift->render('index.tt');
};

any '/list' => sub {
    my ($c) = @_;
    my $mkdn_dir = dir($c->base_dir, 'tmpl', 'mkdn');
    my @entries;
    for my $file ( sort { $b->stat->mtime <=> $a->stat->mtime } grep { -f $_ && $_ =~ /\.mkdn$/ } $mkdn_dir->children ){
        my $title = 'unknown';

        my $entry = DietWiki::Entry->new($file->absolute);
        my $path = $file->basename;
        $path =~ s/\.mkdn$//;
        push @entries,{
            title => $entry->title,
            path  => '/entry/'.$path,
            mtime => localtime($file->stat->mtime).'',
        };
    }
    $c->render('list.tt',{
        entries => \@entries,
    });
};

any '/entry/:entry' => sub {
    my ($c, $args) = @_;
    return $c->res_404 if $args->{entry} =~ /[^-_0-9a-zA-Z]/;
    my $mkdn_file = File::Spec->catfile($c->base_dir, 'tmpl', 'mkdn', $args->{entry}.'.mkdn');
    return $c->res_404 unless -f $mkdn_file;
    my $entry = DietWiki::Entry->new($mkdn_file);
    my $mkdn = Text::Xslate::mark_raw($entry->body_as_html);
    $c->render('entry.tt', {mkdn => $mkdn});
};

1;

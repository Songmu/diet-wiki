package DietWiki::Web::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::Lite;
use File::Spec;
use Path::Class;
use Time::Piece;
use Text::MultiMarkdown qw/markdown/;

any '/' => sub {
    my ($c) = @_;
    my $mkdn_dir = dir($c->base_dir, 'tmpl', 'mkdn');
    my @entries;
    for my $file ( sort { $b->stat->mtime <=> $a->stat->mtime } grep { -f $_ && $_ =~ /\.mkdn$/ } $mkdn_dir->children ){
        my $title = 'unknown';
        my $reader = $file->open('<:utf8');
        while (my $line = $reader->getline){
            if ( $line =~ /^#/ ){
                $line =~ s/^[\s#]+//;
                $line =~ s/[\s#]+$//;
                $title = $line;
                last;
            }
        }
        my $path = $file->basename;
        $path =~ s/\.mkdn$//;
        push @entries,{
            title => $title,
            path  => $path,
            mtime => localtime($file->stat->mtime).'',
        };
    }
    $c->render('index.tt',{
        entries => \@entries,
    });
};

any '/:entry' => sub {
    my ($c, $args) = @_;
    return $c->res_404 if $args->{entry} =~ /[^-_0-9a-zA-Z]/;
    my $mkdn_file = File::Spec->catfile($c->base_dir, 'tmpl', 'mkdn', $args->{entry}.'.mkdn');
    return $c->res_404 unless -f $mkdn_file;
    my $mkdn = Text::Xslate::mark_raw(markdown(do{
        undef $/;
        open my $fh,'<:utf8',$mkdn_file or die "$! :cannot open $mkdn_file";
        <$fh>;
    }));
    $c->render('entry.tt', {mkdn => $mkdn});
};

1;

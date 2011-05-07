package DietWiki::Web::Dispatcher;
use strict;
use warnings;
use Amon2::Web::Dispatcher::Lite;
use File::Spec;
use Text::MultiMarkdown qw/markdown/;

any '/' => sub {
    my ($c) = @_;
    my $mkdn_dir = File::Spec->catdir($c->base_dir, 'tmpl', 'mkdn');
    opendir my $dh, $mkdn_dir or die "$!:$mkdn_dir";
    my @entries;
    while ( my $file = readdir $dh ){
        next if $file !~ /^[-_0-9a-zA-Z]+\.mkdn$/;
        my $file_path = File::Spec->catfile($mkdn_dir, $file);
        next unless -f $file_path;
        open my $fh,'<:utf8',$file_path or die "$! :cannot open $file_path";
        my $title = 'unknown';
        while (my $line = <$fh>){
            if ( $line =~ /^#/ ){
                $line =~ s/^[\s#]+//;
                $line =~ s/[\s#]+$//;
                $title = $line;
                last;
            }
        }
        my $path = $file;
        $path =~ s/\.mkdn$//;
        push @entries,{
            title => $title,
            path  => $path,
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

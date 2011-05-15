package DietWiki::Entry;
use strict;
use warnings;
use utf8;
use YAML;
use Text::MultiMarkdown qw/markdown/;

sub new {
    my ($kls, $file) = @_;
    die 'no file' unless $file;
    die 'file not found' unless -f -r $file;
    my $self = {};
    $self->{content_raw} = do {
        local $/;
        open my $fh,'<:utf8',$file or die $!;
        <$fh>;
    };
    bless $self, $kls;
    $self->_parse_content;
}


sub body {
    shift->{body};
}

sub body_as_html {
    my $self = shift;
    $self->{body_as_html} = markdown($self->body) unless $self->{body_as_html};
    $self->{body_as_html};
}

sub headers {
    my ($self, $key) = @_;
    $self->{headers} = YAML::Load($self->{header_raw}) if !$self->{headers} && $self->{header_raw};
    $self->{headers} ||= {};
    if ($key && ref $self->{headers} eq 'HASH'){
        return $self->{headers}{$key};
    }
    else{
        return $self->{headers};
    }
}

sub title {
    my $self = shift;
    $self->{title} = sub {
        for my $line ( split /\n/, $self->body ){
            if ( $line =~ /^#/ ){
                $line =~ s/^[#\s]+//;
                $line =~ s/[#\s]+$//;
                return $line;
            }
        }
    }->() unless $self->{title};
    $self->{title} ||= 'unknown';
    $self->{title};
}

sub _parse_content {
    my $self = shift;
    my ($header, $body) = split /\n---\n/ms, $self->{content_raw}, 2;
    ($header, $body) = ('', $header) unless $body;
    $header .= "\n" if $header;

    $self->{body}   = $body;
    $self->{header_raw} = $header;
    $self;
}



1;

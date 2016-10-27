package Getopt::Long::Subcommand::Util;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       detect_getopt_long_subcommand_script
               );

our %SPEC;

$SPEC{detect_getopt_long_subcommand_script} = {
    v => 1.1,
    summary => 'Detect whether a file is a Getopt::Long::Subcommand-based CLI script',
    description => <<'_',

The criteria are:

* the file must exist and readable;

* (optional, if `include_noexec` is false) file must have its executable mode
  bit set;

* content must start with a shebang C<#!>;

* either: must be perl script (shebang line contains 'perl') and must contain
  something like `use Getopt::Long::Subcommand`;

_
    args => {
        filename => {
            summary => 'Path to file to be checked',
            schema => 'str*',
            cmdline_aliases => {f=>{}},
            pos => 0,
        },
        string => {
            summary => 'String to be checked',
            schema => 'buf*',
        },
        include_noexec => {
            summary => 'Include scripts that do not have +x mode bit set',
            schema  => 'bool*',
            default => 1,
        },
    },
    args_rels => {
        req_one => ['filename', 'string'],
    },
};
sub detect_getopt_long_subcommand_script {
    my %args = @_;

    (defined($args{filename}) xor defined($args{string}))
        or return [400, "Please specify either filename or string"];
    my $include_noexec  = $args{include_noexec}  // 1;

    my $yesno = 0;
    my $reason = "";
    my %extrameta;

    my $str = $args{string};
  DETECT:
    {
        if (defined $args{filename}) {
            my $fn = $args{filename};
            unless (-f $fn) {
                $reason = "'$fn' is not a file";
                last;
            };
            if (!$include_noexec && !(-x _)) {
                $reason = "'$fn' is not an executable";
                last;
            }
            my $fh;
            unless (open $fh, "<", $fn) {
                $reason = "Can't be read";
                last;
            }
            # for efficiency, we read a bit only here
            read $fh, $str, 2;
            unless ($str eq '#!') {
                $reason = "Does not start with a shebang (#!) sequence";
                last;
            }
            my $shebang = <$fh>;
            unless ($shebang =~ /perl/) {
                $reason = "Does not have 'perl' in the shebang line";
                last;
            }
            seek $fh, 0, 0;
            {
                local $/;
                $str = <$fh>;
            }
        }
        unless ($str =~ /\A#!/) {
            $reason = "Does not start with a shebang (#!) sequence";
            last;
        }
        unless ($str =~ /\A#!.*perl/) {
            $reason = "Does not have 'perl' in the shebang line";
            last;
        }
        if ($str =~ /^\s*(use|require)\s+(Getopt::Long::Subcommand)(\s|;)/m) {
            $yesno = 1;
            $extrameta{'func.module'} = $2;
            last DETECT;
        }
        $reason = "Can't find any statement requiring Getopt::Long::Subcommand module";
    } # DETECT

    [200, "OK", $yesno, {"func.reason"=>$reason, %extrameta}];
}

#ABSTRACT: Utilities for Getopt::Long::Subcommand

=head1 SEE ALSO

L<Getopt::Long::Subcommand>

=cut

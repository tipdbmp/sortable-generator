use strictures 1;
use v5.16;
use Docopt;
use File::Slurp;
use Encode;
use List::MoreUtils qw|none|;

use Cwd (); use File::Basename ();
my $__DIR__ = File::Basename::dirname(Cwd::abs_path(__FILE__));

# my $fields = ['A' .. 'D'];
# my $non_searchable_fields = [];
# my $searchable_fields = [ grep { my $field = $_; none { $_ eq $field } @$non_searchable_fields } @$fields ];
# use DDP; p $searchable_fields;
# exit 1;


my $MY_NAME  = __FILE__;
my $USAGE = <<"END_USAGE";
Usage:
    $MY_NAME <data-name> <data-source-file> <fields>... [--non-searchable-field=<field>... ] [ --output-filename=<file> ]

Options:
    -o=<file>,  --output-filename
    -s=<field>, --non-searchable-field

END_USAGE

@ARGV = map { decode('UTF-8', $_) } @ARGV;
# @ARGV = map { decode('windows-1251', $_) } @ARGV;
my %op = %{ docopt(doc => $USAGE) };
# use DDP; p %op;

my $template = read_file("$__DIR__/sortable-data-template.html", bindmode => ':encoding(UTF-8)');
my $data     = read_file($op{'<data-source-file>'}, binmode => ':encoding(UTF-8)');
my @fields   = @{ $op{'<fields>'} };


# the data is expected to be in the format (aka JSON):
# [
#     { some: 'data', data: 2 },
#     { some: 'other', data: 'or something' },
#     { some: 'end', data: false },
# ]

# add some indentation for clarity
#
s/^\s+//, s/\s+$// for $data;
my $data_indent = ' ' x (1 * 4);
$data = $data_indent . $data;
$data =~ s/\n/\n$data_indent/g;

my $TABLE_HEADERS = '';
for my $field (@fields)
{
    my $displayed = $field;
    $displayed =~ s/_/ /g;
    $TABLE_HEADERS .= ' ' x (4 * 4) . qq|<td ng-click="by_what='$field'; reversed=!reversed;">$displayed</td>| . "\n";
}

my $DATA_FIELDS = '';
for my $field (@fields)
{
    $DATA_FIELDS .= ' ' x (3 * 4) . qq|<td ng-bind-html-unsafe="d.$field"></td>| . "\n";
}

my $SEARCHED_FIELDS = [ grep { my $field = $_; none { $_ eq $field } @{ $op{'--non-searchable-field'} } } @fields ];
$SEARCHED_FIELDS    = '[' . join(', ', map { "'$_'" } @$SEARCHED_FIELDS) . ']';

$template =~ s/\$#{NAME}#\$/$op{'<data-name>'}/g;
$template =~ s/\$#{DATA}#\$/$data/;
$template =~ s/\$#{TABLE_HEADERS}#\$/$TABLE_HEADERS/;
$template =~ s/\$#{DATA_FIELDS}#\$/$DATA_FIELDS/;
$template =~ s/\$#{SEARCHED_FIELDS}#\$/$SEARCHED_FIELDS/;

if ($op{'--output-filename'})
{
    write_file($op{'--output-filename'}, { binmode => ':encoding(UTF-8)' }, $template);
    # write_file($op{'--output-filename'}, encode('UTF-8', $template));
}
else
{
    say encode('UTF-8', $template);
}

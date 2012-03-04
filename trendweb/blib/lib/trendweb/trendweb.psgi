use strict;
use warnings;

use trendweb;

my $app = trendweb->apply_default_middlewares(trendweb->psgi_app);
$app;


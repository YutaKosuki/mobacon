use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;

our $VERSION = '0.12';

# put your configuration here
sub load_config {
    my $c = shift;

    my $mode = $c->mode_name || 'development';

    +{
        'DBI' => [
            "dbi:SQLite:dbname=$mode.db",
            '',
            '',
        ],
    }
}

get '/' => sub {
    my $c = shift;
    return $c->create_response(200, [], ['Hello, world!amon2lite']);
#    my $result = $c->dbh->select_row_arrayref...
};

__PACKAGE__->load_plugins(qw/Web::JSON/);

get '/testreturnjson' => sub {
    my $c = shift;

    my $max_id = $c->db->select_row(
        q{SELECT MAX(id) FROM user_info}
    );


    return $c->render_json($max_id);
};

get '/testdb' => sub {
    my $c = shift;
    my $db = $c->db;
    my $txn = $db->txn_scope;

    $db->query(
        q{INSERT INTO userinfo (id, name, password, num_lend) VALUES (2, 'Yuta2', 'bbb', 0)}
    );
    my $last_id = $db->last_insert_id;

    $txn->commit;

    my $row = $db->select_row(
        q{SELECT * FROM userinfo LIMIT 1},
        $last_id
    );

    my $max_id = $c->db->select_row(
        q{SELECT MAX(id) FROM user_info}
    );

    return $c->render_json($max_id);

};

#mobacon program-------------------------------------

#data reset
post '/admin/reset' => sub {
    my $c = shift;
    my $db = $c->db;

    my $txn = $db->txn_scope;
    my $last_id = $db->last_insert_id;
  
    $db->query(
        q{DELETE FROM user_info },
        $last_id
    );
    $txn->commit;
 
    $db->query(
        q{DELETE FROM lend_info },
        $last_id
    );  
    $txn->commit;
   
     return $c->create_response(204, [], ['OK']);
};

post '/user/register' => sub {
    my $c = shift;
    my $username = $c->req->param('username');
    my $password = $c->req->param('password');

    my $exists = $->db->select_row(
        q{SELECT id FROM user_info WHERE name = ?;}, $username);

    if($exists) {
        my $res = $c->render_json({message => "The name has already been registered."});
        $res->status(409);
	return $res;
    }

    my $max_id = $c->db->select_one(
        q{SELECT MAX(id) FROM user_info}
    );

    my $id = $max_id + 1;
    
    my $api_key = md5_hex($username.$password);
    my $lend_num = 0;
   # my $txn = $c->db->txn_scope;

    $c->db->query(
        q{INSERT INTO user_info (id, name, password, api_key , num_lend) VALUES (?, ?, ?, ? , ?);}, $id, $username, $password, $api_key, $lend_num
    );
    my $last_id = $c->db->last_insert_id;

    #$txn->commit;

    return $c->render_json({
        id => $id, username => $username, api_key => $api_key,
    });    
};

get '/user/{username}' => sub {
    my ($c, $args) = @_;
    my $key = $args->{username} || die "oops";
    my $row = $c->db->select_row(
        q{SELECT * FROM user_info WHERE name = ? LIMIT 1},
        $key,
    );

    if($row) {
        return $c->render_json($row) 
    } else {
        return $c->create_response(404, ['www/x-form-urlencoded'], ['Not Found']);
    }
};

#----------------------------------------------------

# load plugins
#__PACKAGE__->load_plugin('Web::CSRFDefender' => {
#    post_only => 1,
#});
 __PACKAGE__->load_plugin('DBI');
# __PACKAGE__->load_plugin('Web::FillInFormLite');
# __PACKAGE__->load_plugin('Web::JSON');

__PACKAGE__->enable_session();

__PACKAGE__->to_app(handle_static => 1);

use DBIx::Sunny;
sub db {
    my $self = shift;
    return $self->{db} ||= $self->_db_connect;
}

sub _db_connect {
    my $self = shift;

    my $datasource = sprintf('dbi:mysql:%s', 'heroku_5fd41a1a4ef843f:us-cdbr-east-05.cleardb.net');

    my $dbh = DBIx::Sunny->connect($datasource, 'b33182896a31b7', 'a87bd966', +{
        RaiseError        => 1,
        mysql_enable_utf8 => 1,} );

    return $dbh;
}

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>mobacon</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/main.js') %]"></script>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="[% uri_for('/static/css/main.css') %]">
</head>
<body>
    <div class="container">
        <header><h1>mobacon</h1></header>
        <section class="row">
            This is a mobacon
        </section>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
</body>
</html>

@@ /static/js/main.js

@@ /static/css/main.css
footer {
    text-align: right;
}

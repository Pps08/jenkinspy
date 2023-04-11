#!/bin/perl -w

use MIME::Lite;
$to = $recepient;
$from = $recepient;
$subject = 'QG mail';
$message = $deploycommand;
 
$msg = MIME::Lite->new(
From => $from,
To => $to,
Subject => "$subject",
Type => 'text/html',
Data => $message);

$msg->send('smtp','bridgeheads.bskyb.com',From => $from);


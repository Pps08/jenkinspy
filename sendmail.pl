#!/bin/perl -w

use MIME::Base64;
$to = $recepient;
$from = $recepient;
$subject = 'QG mail';
$message = $deploycommand;
 
$msg = MIME::Base64->new(
From => $from,
To => $to,
Subject => "$subject",
Type => 'text/html',
Data => $message);

$msg->send('smtp','bridgeheads.bskyb.com',From => $from);


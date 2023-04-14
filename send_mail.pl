use Mail::Sendmail;
 
%mail = ( To      => $recepient,
          From    => $recepient,
          Message => $deploycommand
         );
 
sendmail(%mail) or die $Mail::Sendmail::error;
 
print "OK. Log says:\n", $Mail::Sendmail::log;

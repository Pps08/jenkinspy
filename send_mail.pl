use Mail::Sendmail;
 
%mail = ( To      => 'priya_parthasarathy@comcast.com',
          From    => 'priya_parthasarathy@comcast.com',
          Message => "Deploycommand"
         );
 
sendmail(%mail) or die $Mail::Sendmail::error;
 
print "OK. Log says:\n", $Mail::Sendmail::log;

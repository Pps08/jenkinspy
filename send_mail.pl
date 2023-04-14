use Mail::Sendmail;
 
%mail = ( To      => "priya_parthasarathy@sky.uk",
          From    => "priya_parthasarathy@sky.uk",
          Message => "Deploycommand"
         );
 
sendmail(%mail) or die $Mail::Sendmail::error;
 
print "OK. Log says:\n", $Mail::Sendmail::log;

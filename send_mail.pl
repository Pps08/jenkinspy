use Mail::Sendmail;
 
%mail = ( To      => 'priya.parthasarathy@sky.uk',
          From    => 'priya.parthasarathy@sky.uk',
          Message => "Deploycommand"
         );
 
sendmail(%mail) or die $Mail::Sendmail::error;
 
print "OK. Log says:\n", $Mail::Sendmail::log;

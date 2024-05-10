
program contd

  implicit none
  character (len=100) :: lawyers
  integer :: x, y, zzz

  x = 2
  y = 1
  zzz = x +        y
  print *, 'zzz = ',zzz
  zzz = x *       y
  print *, 'zzz = ',zzz
  zzz = x -y
  print *, 'zzz = ',zzz

  lawyers = 'Jones & Clay & Davis'
  print *,'LAWYERS_1 = <',trim(lawyers),'>'

  lawyers = 'Jones! &! Clay! &! Davis!'
  print *,'LAWYERS_2 = <',trim(lawyers),'>'






  lawyers = 'Jones & Clay & Davis'
  print *,'LAWYERS_4 = <',trim(lawyers),'>'

  lawyers = 'Jones & Clay & Davis'
  print *,'LAWYERS_5 = <',trim(lawyers),'>'

  lawyers = 'Jones & ''Clay'' & Davis'
  print *,'LAWYERS_6 = <',trim(lawyers),'>'

  lawyers = 'Jones & ""Clay"" & Davis'
  print *,'LAWYERS_7 = <',trim(lawyers),'>'

  lawyers = "Jones & ""Clay"" & Davis"
  print *,'LAWYERS_8 = <',trim(lawyers),'>'

  lawyers = "Jones & ''Clay'' & Davis"
  print *,'LAWYERS_9 = <',trim(lawyers),'>'

  lawyers = 'Jones & Clay &  Davis'
  print *,'LAWYERS_10 = <',trim(lawyers),'>'

  lawyers = 'Jones & Clay & Davis'
  print *,'LAWYERS_11 = <',trim(lawyers),'>'

  lawyers =  'Jones & Clay & Davis'
  print *,'LAWYERS_12 = <',trim(lawyers),'>'

  lawyers = 'Jones & Clay & Davis'
  print *,'LAWYERS_13 = <<',trim(lawyers),">>"





  lawyers = 'Jones & ''Clay'' & Davis'
  print *,'LAWYERS_14 = <',trim(lawyers),'>'

  lawyers = 'Jones & ''Clay'' & Davis'
  print *,'LAWYERS_15 = <',trim(lawyers),'>'
















end program contd

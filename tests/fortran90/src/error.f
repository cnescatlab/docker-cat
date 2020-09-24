PROGRAM ESSAI

      INTEGER, parameter :: EOF = -1
      INTEGER, parameter :: f_unit = 15 
      INTEGER            :: count = 0
      INTEGER            :: ios  

      CHARACTER(128)     :: c_buffer 

      OPEN (UNIT = f_unit, FILE = '/etc/passwd', STATUS = 'OLD')
      READ (UNIT = f_unit, FMT = 100, IOSTAT = ios) c_buffer

      DO WHILE(ios >= 0)

         WRITE (*,*) count, c_buffer 
         count = count + 1
         READ (UNIT = f_unit, FMT = 100, IOSTAT = ios) c_buffer

      END DO
100   FORMAT(A128)

END PROGRAM ESSAI 

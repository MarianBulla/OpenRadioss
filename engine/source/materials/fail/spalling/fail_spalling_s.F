Copyright>        OpenRadioss
Copyright>        Copyright (C) 1986-2025 Altair Engineering Inc.
Copyright>
Copyright>        This program is free software: you can redistribute it and/or modify
Copyright>        it under the terms of the GNU Affero General Public License as published by
Copyright>        the Free Software Foundation, either version 3 of the License, or
Copyright>        (at your option) any later version.
Copyright>
Copyright>        This program is distributed in the hope that it will be useful,
Copyright>        but WITHOUT ANY WARRANTY; without even the implied warranty of
Copyright>        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Copyright>        GNU Affero General Public License for more details.
Copyright>
Copyright>        You should have received a copy of the GNU Affero General Public License
Copyright>        along with this program.  If not, see <https://www.gnu.org/licenses/>.
Copyright>
Copyright>
Copyright>        Commercial Alternative: Altair Radioss Software
Copyright>
Copyright>        As an alternative to this open-source version, Altair also offers Altair Radioss
Copyright>        software under a commercial license.  Contact Altair to discuss further if the
Copyright>        commercial version may interest you: https://www.altair.com/radioss/.
      !||====================================================================
      !||    fail_spalling_s   ../engine/source/materials/fail/spalling/fail_spalling_s.F
      !||--- called by ------------------------------------------------------
      !||    mmain             ../engine/source/materials/mat_share/mmain.F90
      !||    mmain8            ../engine/source/materials/mat_share/mmain8.F
      !||    mulaw             ../engine/source/materials/mat_share/mulaw.F90
      !||    mulaw8            ../engine/source/materials/mat_share/mulaw8.F90
      !||    usermat_solid     ../engine/source/materials/mat_share/usermat_solid.F
      !||====================================================================
      SUBROUTINE FAIL_SPALLING_S (
     1     NEL     ,NUPARAM ,
     2     TIME    ,TIMESTEP,UPARAM  ,NGL    ,
     3     SIGNXX  ,SIGNYY  ,SIGNZZ  ,SIGNXY ,SIGNYZ  ,SIGNZX ,
     4     DPLA    ,EPSP    ,TSTAR   ,OFF    ,
     5     LF_DAMMX,DFMAX   ,TDELE   ,OFFG   )
C-----------------------------------------------
C     Johnson cook + spalling          
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C---------+---------+---+---+--------------------------------------------
C VAR     | SIZE    |TYP| RW| DEFINITION
C---------+---------+---+---+--------------------------------------------
C NEL     |  1      | I | R | SIZE OF THE ELEMENT GROUP NEL 
C NUPARAM |  1      | I | R | SIZE OF THE USER PARAMETER ARRAY
C---------+---------+---+---+--------------------------------------------
C TIME    |  1      | F | R | CURRENT TIME
C TIMESTEP|  1      | F | R | CURRENT TIME STEP
C UPARAM  | NUPARAM | F | R | USER FAILURE PARAMETER ARRAY
C---------+---------+---+---+--------------------------------------------
C SIGNXX  | NEL     | F | W | NEW ELASTO PLASTIC STRESS XX
C SIGNYY  | NEL     | F | W | NEW ELASTO PLASTIC STRESS YY
C ...     |         |   |   |
C ...     |         |   |   |
C---------+---------+---+---+--------------------------------------------
C OFF     | NEL     | F |R/W| DELETED ELEMENT FLAG (=1. ON, =0. OFF)
C OFFG    | NEL     | F |R/W| GLOBAL ELEMENT FLAG 
C---------+---------+---+---+--------------------------------------------
#include "mvsiz_p.inc"
#include "scr17_c.inc"
#include "units_c.inc"
#include  "comlock.inc"
#include  "param_c.inc"
#include      "impl1_c.inc"
C-----------------------------------------------
C   I N P U T   A r g u m e n t s
C-----------------------------------------------
      INTEGER NEL, NUPARAM, NGL(NEL)
      INTEGER, INTENT(IN) :: LF_DAMMX
      my_real TIME,TIMESTEP,UPARAM(*),
     .   SIGNXX(NEL),SIGNYY(NEL),SIGNZZ(NEL),
     .   SIGNXY(NEL),SIGNYZ(NEL),SIGNZX(NEL),
     .   DPLA(NEL),EPSP(NEL),TSTAR(NEL), OFFG(*)     
C-----------------------------------------------
C   O U T P U T   A r g u m e n t s
C-----------------------------------------------
cc      my_real
 
C-----------------------------------------------
C   I N P U T   O U T P U T   A r g u m e n t s 
C-----------------------------------------------
      my_real OFF(NEL),DFMAX(NEL,LF_DAMMX),TDELE(NEL)
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER I,J,IDEL,IDEV,IFLAG,INDX(MVSIZ),IADBUF,NINDX,
     .        NINDEX,INDEX(MVSIZ),IFAIL,JJ,ISPALL
      my_real 
     .        D1,D2,D3,D4,D5,
     .        EPSP0,P,PMIN,EPSF,SVM,SCALE,SXX,SYY,SZZ
C--------------------------------------------------------------
       D1 = UPARAM(1)
       D2 = UPARAM(2)
       D3 = UPARAM(3)
       D4 = UPARAM(4)
       D5 = UPARAM(5)        
       EPSP0 = UPARAM(6)
       PMIN  = UPARAM(7)
       IFLAG = INT(UPARAM(8)) 
C-----------------------------------------------
      IDEL=0
      IDEV=0
C      
      DO I=1,NEL
        ISPALL = 1
        IF(IFLAG==2)THEN
          IDEL = 1
        ELSEIF(IFLAG==3)THEN
          IDEV = 1  
        ELSEIF(IFLAG==4)THEN
         IDEL = 1
         ISPALL = 2
        END IF
      END DO
C
        DO I=1,NEL
          IF(OFF(I)<EM01) OFF(I)=ZERO
          IF(OFF(I)<ONE) OFF(I)=OFF(I)*FOUR_OVER_5
        END DO
C      
      IF(IDEL==1)THEN
       NINDX=0  
       DO I=1,NEL
        IF((IFLAG==2.OR.IFLAG==4).
     .                AND.OFF(I)==ONE.AND.DPLA(I)/=ZERO
     .                .AND.OFFG(I)>ZERO)THEN
         P = THIRD*(SIGNXX(I) + SIGNYY(I) + SIGNZZ(I))
         SXX = SIGNXX(I) - P
         SYY = SIGNYY(I) - P
         SZZ = SIGNZZ(I) - P
         SVM =HALF*(SXX**2 + SYY**2 + SZZ**2)
     .          +SIGNXY(I)**2 + SIGNZX(I)**2 + SIGNYZ(I)**2
         SVM=SQRT(THREE*SVM)
         EPSF = D3*P/MAX(EM20,SVM)
         EPSF = (D1 + 
     .           D2*EXP(EPSF))*(ONE 
     .                  + D4*LOG(MAX(ONE,EPSP(I)/EPSP0)))
     .                    *(ONE + D5*TSTAR(I))
         IF(EPSF>ZERO) DFMAX(I,2) = DFMAX(I,2) + DPLA(I)/EPSF       
         IF(DFMAX(I,2)>=ONE.AND.OFF(I)==ONE) THEN
          DFMAX(I,2) = ONE
          OFF(I)=FOUR_OVER_5
          NINDX=NINDX+1
          INDX(NINDX)=I
          TDELE(I) = TIME                  
         ENDIF
        ENDIF 
       ENDDO
       IF(NINDX>0.AND.IMCONV==1)THEN
        DO J=1,NINDX
#include "lockon.inc"
         WRITE(IOUT, 1000) NGL(INDX(J))
         WRITE(ISTDO,1100) NGL(INDX(J)),TIME
#include "lockoff.inc"
        END DO
       END IF         
      ENDIF
Cc deviatoric will be vanished      
      IF(IDEV==1)THEN
       NINDX=0 
       NINDEX = 0 
       DO I=1,NEL
        IF(IFLAG==3.AND.OFF(I)==ONE.AND.DPLA(I)/=ZERO.AND.
     .         OFFG(I)>ZERO)THEN
         IF (DFMAX(I,2)<ONE)THEN
          P = THIRD*(SIGNXX(I) + SIGNYY(I) + SIGNZZ(I))
          SXX = SIGNXX(I) - P
          SYY = SIGNYY(I) - P
          SZZ = SIGNZZ(I) - P
          SVM =HALF*(SXX**2+ SYY**2 + SZZ**2)
     .          +SIGNXY(I)**2 + SIGNZX(I)**2 + SIGNYZ(I)**2
          SVM=SQRT(THREE*SVM)
          EPSF = D3*P/MAX(EM20,SVM)
          EPSF = (D1 + 
     .           D2*EXP(EPSF))*(ONE 
     .                  + D4*LOG(MAX(ONE,EPSP(I)/EPSP0)))
     .                    *(ONE + D5*TSTAR(I))
          IF(EPSF>ZERO) DFMAX(I,2) = DFMAX(I,2) + DPLA(I)/EPSF
          IF(DFMAX(I,2)>=ONE.AND.OFF(I)==ONE) THEN
           DFMAX(I,2) = ONE
           NINDX=NINDX+1
           INDX(NINDX)=I
           SIGNXX(I) =   P
           SIGNYY(I) =   P
           SIGNZZ(I) =   P
           SIGNXY(I) = ZERO
           SIGNYZ(I) = ZERO
           SIGNZX(I) = ZERO                 
          ENDIF
         ELSE 
          P = THIRD*(SIGNXX(I) + SIGNYY(I) + SIGNZZ(I))
          SIGNXX(I) =   P
          SIGNYY(I) =   P
          SIGNZZ(I) =   P
          SIGNXY(I) = ZERO
          SIGNYZ(I) = ZERO
          SIGNZX(I) = ZERO
         ENDIF
        ENDIF  
       ENDDO
       IF(NINDX>0.AND.IMCONV==1)THEN
        DO J=1,NINDX
         I = INDX(J)
#include "lockon.inc"
         WRITE(IOUT, 2000) NGL(I)
         WRITE(ISTDO,2100) NGL(I),TIME
#include "lockoff.inc"
        END DO
       END IF           
      ENDIF
C...Spalling
        NINDEX = 0
        NINDX  = 0
        DO I=1,NEL
          P = -THIRD*(SIGNXX(I) + SIGNYY(I) + SIGNZZ(I))
          DFMAX(I,3) = MAX(DFMAX(I,3),MIN(P,ZERO)/PMIN)
          IF (ISPALL==1 .AND. OFFG(I)>ZERO) THEN
            IF (DFMAX(I,3) < ONE) THEN 
              IF (DFMAX(I,3) >= ONE)THEN
                DFMAX(I,3) = ONE
                SIGNXX(I)= ZERO
                SIGNYY(I)= ZERO
                SIGNZZ(I)= ZERO
                SIGNXY(I)= ZERO
                SIGNZX(I)= ZERO
                SIGNYZ(I)= ZERO
                NINDX=NINDX+1
                INDX(NINDX)=I 
              ENDIF
            ELSE
              SIGNXX(I) = -MAX(P , ZERO)
              SIGNYY(I) = -MAX(P , ZERO)
              SIGNZZ(I) = -MAX(P , ZERO)
              SIGNXY(I)= ZERO
              SIGNZX(I)= ZERO
              SIGNYZ(I)= ZERO
            ENDIF
          ELSEIF(ISPALL==2.AND.P<=PMIN.AND.OFF(I)==ONE.AND.
     .         OFFG(I)>ZERO)THEN
            OFF(I)= FOUR_OVER_5
            NINDEX=NINDEX+1
            INDEX(NINDEX)=I
            TDELE(I) = TIME  
          ENDIF 
        ENDDO
C
        IF (NINDX>0.AND.IMCONV==1) THEN
        DO J=1,NINDX
#include "lockon.inc"
        WRITE(IOUT, 3000) NGL(INDX(J))
        WRITE(ISTDO,3100) NGL(INDX(J)),TIME
#include "lockoff.inc"
        END DO
       END IF
C       
        IF (NINDEX>0.AND.IMCONV==1) THEN
        DO J=1,NINDEX
#include "lockon.inc"
        WRITE(IOUT, 3200) NGL(INDEX(J))
        WRITE(ISTDO,3300) NGL(INDEX(J)),TIME
#include "lockoff.inc"
        END DO
       END IF  
C-------------Maximum Damage storing for output : 0 < DFMAX < 1--------------
       DO I=1,NEL
          DFMAX(I,1) = MAX(DFMAX(I,2),DFMAX(I,3))
       ENDDO                   
C-----------------------------------------------
 1000 FORMAT(1X,'DELETE SOLID ELEMENT NUMBER ',I10)
 1100 FORMAT(1X,'DELETE SOLID ELEMENT NUMBER ',I10,
     .          ' AT TIME :',1PE12.4)
CC     
 2000 FORMAT(1X,' DEVIATORIC STRESS WILL BE VANISHED',I10)
 2100 FORMAT(1X,' DEVIATORIC STRESS WILL BE VANISHED',I10,
     .          ' AT TIME :',1PE12.4)
 3000 FORMAT(1X,'SPALLING OF SOLID ELEMENT NUMBER ',I10)
 3100 FORMAT(1X,'SPALLING OF SOLID ELEMENT NUMBER ',I10,
     .          ' AT TIME :',G11.4)
C     
 3200 FORMAT(1X,'DELETE SOLID ELEMENT (SPALLING) NUMBER ',I10)
 3300 FORMAT(1X,'DELETE SOLID ELEMENT (SPALLING) NUMBER ',I10,
     .          ' AT TIME :',G11.4)          
      RETURN
      END

//Copyright>    OpenRadioss
//Copyright>    Copyright (C) 1986-2025 Altair Engineering Inc.
//Copyright>
//Copyright>    This program is free software: you can redistribute it and/or modify
//Copyright>    it under the terms of the GNU Affero General Public License as published by
//Copyright>    the Free Software Foundation, either version 3 of the License, or
//Copyright>    (at your option) any later version.
//Copyright>
//Copyright>    This program is distributed in the hope that it will be useful,
//Copyright>    but WITHOUT ANY WARRANTY; without even the implied warranty of
//Copyright>    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//Copyright>    GNU Affero General Public License for more details.
//Copyright>
//Copyright>    You should have received a copy of the GNU Affero General Public License
//Copyright>    along with this program.  If not, see <https://www.gnu.org/licenses/>.
//Copyright>
//Copyright>
//Copyright>    Commercial Alternative: Altair Radioss Software
//Copyright>
//Copyright>    As an alternative to this open-source version, Altair also offers Altair Radioss
//Copyright>    software under a commercial license.  Contact Altair to discuss further if the
//Copyright>    commercial version may interest you: https://www.altair.com/radioss/.
//    
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <fcntl.h>



#ifdef _WIN32
/* Windows includes */
#include <windows.h>
#include <process.h>
#include <io.h>
#include <sys\types.h>
#include <sys/stat.h>


#elif 1

/* Linux includes */
#include <sys/resource.h>
#include <sys/types.h>
#include <time.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dlfcn.h>
#define _FCALL
#include <math.h>
#include <stdbool.h>

#endif

#include "h3dpublic_defs.h"
#include "h3dpublic_export.h"

#define _FCALL 

#include "h3d_values.h"

#ifdef MYREAL4
#define my_real float
#endif

#ifdef MYREAL8
#define my_real double
#endif

extern "C" 
/*=================================================================*/
{



/*=================================================================*/
/*        C_H3D_UPDATE_H3DFILE_SHELL_SCALAR                        */
/*=================================================================*/

void c_h3d_update_shell_scalar_(my_real *TT,int *IH3D, int *ITAB, int *NUMNOD, int *IXC, int *NIXC, int *NUMELC, int *IPARTC,
                           int *IXTG, int *NIXTG, int *NUMELTG, int *IPARTTG, float *FUNC ,int *ID_ELEM,int *CPT_DATATYPE,
                           int *ITY_ELEM, int *NUMELS, int *NUMELQ , int *NUMELT , int *NUMELP , int *NUMELR, int *IS_WRITTEN,int *SHELL_STACKSIZE)
{
    int elt;
    int i;
    int offset;
    H3D_ID elem_id;
    H3D_ID comp_id;
//
    // initialize 
    try {
        // create Subcase (Loadcase)
        unsigned int       max_sims = 10;
        unsigned int      sub_count = 1;
        float elem_result[] = { 0.0f, 0.0f, 0.0f };

        // create Result Data sets
        unsigned int num_corners = 0;
        unsigned int   num_modes = 0;
        bool             complex = false;
        float value[1] ;

        sim_idx = *IH3D;


        if( *NUMELC != 0)
          {

          rc = Hyper3DDatasetBegin(h3d_file, *NUMELC, sim_idx, subcase_id, H3D_DS_ELEM, 
                                        H3D_DS_SCALAR, num_corners, num_modes, *CPT_DATATYPE, 
                                        0, sh4n_poolname_id, complex); 
          if( !rc ) throw rc;

          offset = 0;

          for( i = 0; i < *SHELL_STACKSIZE; i++ ) 
          {
            elt=IS_WRITTEN[i]-1;
            if( ITY_ELEM[elt] == 3  ) 
            { 
              elem_id = ID_ELEM[elt];
              elem_result[0] = FUNC[i];
              // printf("SH elem = %i, elem_result[elt] = %f\n",elem_id,elem_result[0]);
              rc = Hyper3DDatasetWrite(h3d_file, elem_id, &elem_result[0]);
            }
          }

          rc = Hyper3DDatasetEnd(h3d_file);
          if( !rc ) throw rc;
        }

        offset = *NUMELC;


        if( *NUMELTG != 0)
          {

          rc = Hyper3DDatasetBegin(h3d_file, *NUMELTG, sim_idx, subcase_id, H3D_DS_ELEM, 
                                        H3D_DS_SCALAR, num_corners, num_modes, *CPT_DATATYPE, 
                                        0, sh3n_poolname_id, complex); 
          if( !rc ) throw rc;

          for( i = 0; i < *SHELL_STACKSIZE; i++ ) 
          {
            elt = IS_WRITTEN[i]-1;
            if( ITY_ELEM[elt] == 7 ) 
            { 
            //  printf("%i - TR elem = %i, ID_ELEM[elt] = %i\n",i,elt,ID_ELEM[elt]);
              elem_id = ID_ELEM[elt];
              elem_result[0] = FUNC[i];
              // printf("TR elem = %i, elem_result[elt] = %f\n",elem_id,elem_result[0]);
              rc = Hyper3DDatasetWrite(h3d_file, elem_id, &elem_result[0]);
            }
          }
          rc = Hyper3DDatasetEnd(h3d_file);
          if( !rc ) throw rc;
        }

    } // end of try

    catch(...)    {
        Hyper3DExportClearError(h3d_file);
    }
}

void _FCALL C_H3D_UPDATE_SHELL_SCALAR(my_real *TT,int *IH3D, int *ITAB, int *NUMNOD, int *IXC, int *NIXC, int *NUMELC, int *IPARTC,
                           int *IXTG, int *NIXTG, int *NUMELTG, int *IPARTTG, float *FUNC ,int *ID_ELEM,int *CPT_DATATYPE,
                           int *ITY_ELEM, int *NUMELS, int *NUMELQ , int *NUMELT , int *NUMELP , int *NUMELR, int *IS_WRITTEN,int *SHELL_STACKSIZE)
{c_h3d_update_shell_scalar_ (TT,IH3D,ITAB,NUMNOD,IXC,NIXC,NUMELC,IPARTC,IXTG,NIXTG,NUMELTG,IPARTTG,FUNC,ID_ELEM,CPT_DATATYPE,ITY_ELEM,
                         NUMELS,NUMELQ,NUMELT,NUMELP,NUMELR,IS_WRITTEN,SHELL_STACKSIZE);}

void c_h3d_update_shell_scalar__ (my_real *TT,int *IH3D, int *ITAB, int *NUMNOD, int *IXC, int *NIXC, int *NUMELC, int *IPARTC,
                           int *IXTG, int *NIXTG, int *NUMELTG, int *IPARTTG, float *FUNC ,int *ID_ELEM,int *CPT_DATATYPE,
                           int *ITY_ELEM, int *NUMELS, int *NUMELQ , int *NUMELT , int *NUMELP , int *NUMELR, int *IS_WRITTEN,int *SHELL_STACKSIZE)
{c_h3d_update_shell_scalar_ (TT,IH3D,ITAB,NUMNOD,IXC,NIXC,NUMELC,IPARTC,IXTG,NIXTG,NUMELTG,IPARTTG,FUNC,ID_ELEM,CPT_DATATYPE,ITY_ELEM,
                         NUMELS,NUMELQ,NUMELT,NUMELP,NUMELR,IS_WRITTEN,SHELL_STACKSIZE);}

void c_h3d_update_shell_scalar (my_real *TT,int *IH3D, int *ITAB, int *NUMNOD, int *IXC, int *NIXC, int *NUMELC, int *IPARTC,
                           int *IXTG, int *NIXTG, int *NUMELTG, int *IPARTTG, float *FUNC ,int *ID_ELEM,int *CPT_DATATYPE,
                           int *ITY_ELEM, int *NUMELS, int *NUMELQ , int *NUMELT , int *NUMELP , int *NUMELR, int *IS_WRITTEN,int *SHELL_STACKSIZE)
{c_h3d_update_shell_scalar_ (TT,IH3D,ITAB,NUMNOD,IXC,NIXC,NUMELC,IPARTC,IXTG,NIXTG,NUMELTG,IPARTTG,FUNC,ID_ELEM,CPT_DATATYPE,ITY_ELEM,
                         NUMELS,NUMELQ,NUMELT,NUMELP,NUMELR,IS_WRITTEN,SHELL_STACKSIZE);}

}

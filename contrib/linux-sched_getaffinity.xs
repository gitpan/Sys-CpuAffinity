#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <stdio.h>
#include <stdlib.h>
#include <sched.h>
#include <linux/unistd.h>
cpu_set_t *sched_getaffinity_set1;
cpu_set_t sched_getaffinity_set2;
int sched_getaffinity_initialized = 0;

void sched_getaffinity_initialize()
{
  if (sched_getaffinity_initialized++) return;
  sched_getaffinity_set1 = &sched_getaffinity_set2;
}

int sched_getaffinity_get_affinity_debug(int pid)
{
  int i, r, z;
  fprintf(stderr,"getaffinity0\n");
  sched_getaffinity_initialize();
  fprintf(stderr,"getaffinity1 pid=%d size=%d cpuset=0x%d\n",
	  (int) pid, (int) CPU_SETSIZE, (int) sched_getaffinity_set1);

  /*
   * Intermittent failure point is here.
   *
   * 2011-06-17 -- seems related to having  hello.xs  compiled into
   *     the distribution.  hello.xs  is pretty trivial, though it
   *     is the only XS code that (currently) refers to  SV*  types
   *     (perl internals).
   *
   *     Happens with the perl5.8.8 that shipped with my CentOS distro,
   *     but not with the (many) other versions of perl I have built
   *     "by hand".
   */

  z = sched_getaffinity((pid_t) pid, CPU_SETSIZE, sched_getaffinity_set1);
  fprintf(stderr,"getaffinity2\n");
  if (z) {
    fprintf(stderr,"getaffinity3 z=%d err=%d\n", z, errno);
    return 0;
  }
  fprintf(stderr,"getaffinity5\n");
  for (i = r = 0; i < CPU_SETSIZE && i < 32; i++) {
    fprintf(stderr,"getaffinity6 i=%d r=%d\n", i, r);
    if (CPU_ISSET(i, &sched_getaffinity_set2)) {
      fprintf(stderr,"getaffinity7\n");
      r |= 1 << i;
      fprintf(stderr,"getaffinity8 r=%d\n", r);
    }
    fprintf(stderr,"getaffinity9\n");
  }
  fprintf(stderr,"getaffinitya\n");
  return r;
}

int sched_getaffinity_get_affinity_no_debug(int pid)
{
  int i, r, z;
  sched_getaffinity_initialize();
  z = sched_getaffinity((pid_t) pid, CPU_SETSIZE, sched_getaffinity_set1);
  if (z) {
    return 0;
  }
  for (i = r = 0; i < CPU_SETSIZE && i < 32; i++) {
    if (CPU_ISSET(i, &sched_getaffinity_set2 )) {
      r |= 1 << i;
    }
  }
  return r;
}

MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity


int 
xs_sched_getaffinity_get_affinity(pid)
int pid
  CODE:
    /*
     * Get process CPU affinity on Linux. 
     * This function crashes sometimes, and I'm not sure why.
     *
     *     http://www.cpantesters.org/cpan/report/5bbdfcbe-6651-11e0-b483-457e42987c1d
     */
    RETVAL = sched_getaffinity_get_affinity_no_debug(pid);
  OUTPUT:
    RETVAL


int
xs_sched_getaffinity_get_affinity_debug(pid)
int pid
  CODE:
    RETVAL = sched_getaffinity_get_affinity_debug(pid);
  OUTPUT:
    RETVAL


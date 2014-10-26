#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <linux/unistd.h>
#include <sched.h>





MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity

int
xs_sched_setaffinity_set_affinity(pid,mask)
	int pid
	int mask
    CODE:
	    static cpu_set_t cpumask;
	    unsigned int len = sizeof(cpumask);
	    int i,r;
	
	    CPU_ZERO(&cpumask);
	    for (i=0; i<32 && i<CPU_SETSIZE; i++) {
		if (0 != (mask & (1 << i))) {
		    CPU_SET(i, &cpumask);
		}
	    }
	    r = sched_setaffinity(pid, len, &cpumask);
	    if (r != 0) {
	      fprintf(stderr,"result: %d %d %s\n", r, errno,
		      errno==EFAULT ? "EFAULT"   /* a supplied memory address was invalid */
		      : errno==EINVAL ? "EINVAL" /* the affinity bitmask contains no
						    processors that are physically on the
						    system, or _cpusetsize_ is smaller than
						    the size of the affinity mask used by
						    the kernel */
		      : errno==EPERM ? "EPERM"   /* the calling process does not have
						    appropriate privilieges. The process
						    calling *sched_setaffinity()* needs an
						    effective user ID equal to the user ID
						    or effective user ID of the process
						    identified by _pid_, or it must possess
						    the _CAP_SYS_NICE_ capability. */
		      : errno==ESRCH ? "ESRCH"   /* the process whose ID is _pid_ could not
						    be found */
		      :"E_WTF");
	    }
		/* Set process affinity on Linux. */
	        /*RETVAL = sched_setaffinity_set_affinity(pid,mask);*/
	    RETVAL = !r;
    OUTPUT:
	RETVAL



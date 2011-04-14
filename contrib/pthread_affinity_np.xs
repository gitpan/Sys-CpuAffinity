#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>


#include <pthread.h>
#include <sched.h>

MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity

int
xs_pthread_self_getaffinity(dummy)
	int dummy
    CODE:
	/*
	 * Retrieves the CPU affinity of the current thread.
	 * For use with NetBSD, but it also might work on Linux and FreeBSD.
	 * On NetBSD, may require super-user.
	 */

	cpuset_t *cset;
	pthread_t pth;
	cpuid_t icpu;
	int error, affinity;

	pth = pthread_self();

	affinity = 0;
	cset = cpuset_create();
	if (cset == NULL) {
	    fprintf(stderr, "pthread_getaffinity_np: failed to create cpuset\n");
	    affinity = -1;
	}
	error = pthread_getaffinity_np(pth, cpuset_size(cset), cset);
	if (error) {
	    fprintf(stderr, "pthread_getaffinity_np returned error: %d\n", error);
	    affinity = -1;
	}
	if (affinity >= 0) {
	    for (icpu = 0; icpu < 8 * cpuset_size(cset); icpu++) {
	        int n = cpuset_isset(icpu, cset);
	        if (n < 0) {
	            break;
	        } else if (n > 0) {
		    affinity |= 1 << icpu;
	        }
 	    }
	}
	if (cset != NULL) cpuset_destroy(cset);
	RETVAL = affinity;
    OUTPUT:
	RETVAL

int 
xs_pthread_self_setaffinity(affinity)
        int affinity
    CODE:
	/*
	 * Sets the CPU affinity for the current thread.
	 */
	cpuset_t *cset;
	pthread_t pth;
	cpuid_t icpu;
	int error, result;

	pth = pthread_self();
	result = 2;

	cset = cpuset_create();
	if (cset == NULL) {
	    fprintf(stderr, "xs_set_pthread_self_affinity: failed to create cpu set\n");
	    result = 0;
	} else {
	    for (icpu = 0; icpu < 8 * cpuset_size(cset); icpu++) {
	        if (affinity & (1 << icpu)) {
		    cpuset_set(icpu, cset);
	        } else {
		    cpuset_clr(icpu, cset);
	        }
	    }
	    error = pthread_setaffinity_np(pth, cpuset_size(cset), cset);
	    if (error) {
		fprintf(stderr, "xs_set_pthread_self_affinity: error %d in pthread_setaffinity_np call\n", error);
		result = 0;
	    } else {
	 	result = 1;
	    }
	}
	if (cset != NULL) cpuset_destroy(cset);
	RETVAL = result;
    OUTPUT:
	RETVAL



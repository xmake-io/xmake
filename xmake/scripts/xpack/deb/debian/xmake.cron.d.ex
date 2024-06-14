#
# Regular cron jobs for the ${PACKAGE_NAME} package
#
0 4	* * *	root	[ -x /usr/bin/${PACKAGE_NAME}_maintenance ] && /usr/bin/${PACKAGE_NAME}_maintenance

#
# Regular cron jobs for the xmake package
#
0 4	* * *	root	[ -x /usr/bin/xmake_maintenance ] && /usr/bin/xmake_maintenance

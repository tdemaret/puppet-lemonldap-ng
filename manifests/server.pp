class puppet-lemonldap-ng::server($domain,$webserver) {

    # Execute OS specific actions
    case $::osfamily {
        'Debian': { 
             class { 'puppet-lemonldap-ng::server::operatingsystem::debian' : webserver => $webserver }
         }
        'RedHat': { 
             class { "puppet-lemonldap-ng::server::operatingsystem::redhat" : webserver => $webserver }
         }
        default: { fail("Module ${module_name} is not supported on ${::operatingsystem}") }
    }

    # LemonLDAP packages
    $packageslemon = ['lemonldap-ng', 'lemonldap-ng-fr-doc']

    package{ $packageslemon :
        ensure    => installed,
    }

    case $webserver {
        'apache': { 
              class { "puppet-lemonldap-ng::server::webserver::apache" : domain => $domain } 
        }
        'nginx' : { 
              class { "puppet-lemonldap-ng::server::webserver::nginx" : domain => $domain }
        }
        default: { fail("Module ${module_name} needs apache or nginx webserver") }
    }

    # Set reload vhost in /etc/hosts
    host{'lemonldap':
        ip      => $::ipaddress,
        host_aliases => "reload.$domain",
    }

    # Change default domain
    exec{ 'change-default-domain':
        command => "sed -i 's/example\.com/$domain/g' /var/lib/lemonldap-ng/conf/lmConf-1.js /var/lib/lemonldap-ng/test/index.pl",
        #command => 'sed -i \'s/example\.com/${domain}/g\' /etc/lemonldap-ng/* /var/lib/lemonldap-ng/conf/lmConf-1.js /var/lib/lemonldap-ng/test/index.pl',
        path    => ['/bin', '/usr/bin'],
        require => Package['lemonldap-ng'],
        onlyif  => "grep -qR 'example.com' /etc/lemonldap-ng/* /var/lib/lemonldap-ng/conf/lmConf-1.js /var/lib/lemonldap-ng/test/index.pl",
    }

}

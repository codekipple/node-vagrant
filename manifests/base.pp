/*
    Relying on import even though its deprecated because as of yet vagrant does not support pointing to a folder of manifest files. Once it does we can stop using imports to keep code separated.
*/

file { '/etc/motd':
content => "
  General dev VM
    - OS: Ubuntu 12.04
    - IP: ${::ipaddress_eth1}
    - Netmask: ${::netmask_eth1}
    - Git
    - Node
    - Ruby: 2.1.2 (using rbenv)
    - apache
    - php
    - composer
    - mysql
    - Grunt CLI
    - Bower
\n"
}

# START stages ------------------------------
/*
    Using stages to make sure apt is up to date before
    we start installing packages in the main stage
*/
if ($stages == "yes") {
    stage { 'first': }
    stage { 'second': }

    Stage['first'] -> Stage['second'] -> Stage['main']

    import 'stages/first.pp'
    import 'stages/second.pp'

    class { 'first_stage':
        stage => first
    }

    class { 'second_stage':
        stage => second
    }

    class { 'apt':
        always_apt_update => false,
        stage => first
    }
}
# END stages ------------------------------


# START paths ------------------------------
# Add some default path values
Exec { path => ['/usr/local/bin','/usr/local/sbin','/usr/bin/','/usr/sbin','/bin','/sbin'], }
# END paths --------------------------------


# START git ------------------------------
package { "git":
    ensure  => latest
}
# END git --------------------------------

# START apache ------------------------------
class { 'apache':  }

file { '/etc/apache2/mods-enabled/rewrite.load':
    ensure => 'link',
    target => '/etc/apache2/mods-available/rewrite.load',
    notify  => Service['apache2'],
    require => Package['apache2']
}
# END apache --------------------------------


# START php ---------------------------------
import 'php/manifests/init.pp'
class { 'php': }
# END php -----------------------------------


# START composer ----------------------------
import 'composer/manifests/init.pp'
class { 'composer': }
# END composer ------------------------------


# START mysql ------------------------------
class { '::mysql::server':
    root_password => 'password'
}
# END mysql --------------------------------


# START nodejs -----------------------------
class { 'nodejs':
    version => 'latest'
}

package { 'grunt-cli':
    ensure   => present,
    provider => 'npm',
    require => Class['nodejs']
}

package { 'bower':
    ensure   => present,
    provider => 'npm',
    require => Class['nodejs']
}
# END nodejs -------------------------------


# START Ruby ------------------------------
rbenv::install { 'vagrant':
    group => 'vagrant'
}
rbenv::compile { '2.1.2':
    user => 'vagrant',
    global => true
}
rbenv::gem { 'capistrano':
    user => 'vagrant',
    ruby => '2.1.2'
}
rbenv::gem { 'wpplugin':
    user => 'vagrant',
    ruby => '2.1.2'
}
# END Ruby --------------------------------

# START htop ------------------------------
package { 'htop':
    ensure   => present
}
# END htop --------------------------------

# START imagick ------------------------------
package { 'php5-imagick':
    ensure   => present
}
# END imagick --------------------------------

import 'sites/*.pp'

import 'dotfiles/init.pp'

import 'nfs/init.pp'

/*
    make sure 'www' folder has correct permissions
*/
file { "/var/www" :
    ensure => directory,
    group => "vagrant",
    owner => "vagrant",
    recurse => false,
}
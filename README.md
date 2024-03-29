# cf_inspector
This tool generates the sequence html report of cloudfoundry.

## Setup
Please setup cloudfoundry all-in-one (below link)
https://github.com/cloudfoundry/vcap/blob/master/README.md

Please setup cf_inspector by manual.

    $ export CF_HOME=~/cloudfoundry
    $ cd ~
    $ wget https://raw.github.com/shouta-dev/cf_inspector/master/cf_inspector/vmc_inspect .
    $ wget https://raw.github.com/shouta-dev/cf_inspector/master/cf_inspector/cf_inspector_ext.rb .
    $ mv ./cf_inspector_ext.rb $CF_HOME/vcap/common/lib/vcap
    $ sudo echo "require 'vcap/cf_inspector_ext'" >> $CF_HOME/vcap/common/lib/vcap/common.rb
    $ $CF_HOME/vcap/bin/vcap restart

## Usage
Please use vmc_inspect command like a normal vmc command.

    $ ruby vmc_inspect info
    
    VMware's Cloud Application Platform
    For support visit http://support.cloudfoundry.com
    
    Target:   http://xxx.vcap.me (v0.999)
    Client:   v0.3.13
    
    User:     xxx@example.com
    Usage:    Memory   (384.0M of 2.0G total)
          Services (1 of 16 total)
          Apps     (3 of 20 total)

    /tmp/vmc_info_20111220_110420.html has been generated.
    
    $ ls /tmp/*.html
    /tmp/vmc_info_20111220_110420.html
    
    $ ruby vmc_inspect list
    $ ruby vmc_inspect push
    ...

## Generated file sample
[sample1](http://cloud.github.com/downloads/shouta-dev/cf_inspector/vmc_list_20111220_135812.html)

## License
Apache2
http://www.apache.org/licenses/LICENSE-2.0

## Contact
[twitter : @shouta_dev](http://twitter.com/shouta_dev/)

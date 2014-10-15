﻿class Vendor < DvmTask
  include Thor::Actions

  desc "init", "create and initialize vendor directory"
  def init
    vendor_path = PRJ_VENDOR
    empty_directory vendor_path
    empty_directory vendor_path + 'imports'
    create_file(PRJ_IMPORTS_FILE, :skip => true) do <<-EOS
# sample imports file for delphivm

# set source url
source "my_imports_path"

# can use environment vars anywhere
# source "\#{ENV['IMPORTS_PATH']}"

# set IDE version
uses 'D150'

# now, you can declare some imports

import "FastReport", "4.13.1" do
  ide_install('dclfs15.bpl','dclfsADO15.bpl', 'dclfsBDE15.bpl', 'dclfsDB15.bpl', 'dclfsIBX15.bpl',
    'dclfsTee15.bpl', 'dclfrxADO15.bpl', 'dclfrxBDE15.bpl', 'dclfrxDBX15.bpl', 'dclfrx15.bpl',
    'dclfrxDB15.bpl', 'dclfrxTee15.bpl', 'dclfrxe15.bpl', 'dclfrxIBX15.bpl')
end

# or if we don't need ide install

import "TurboPower", "7.0.0"



# repeat for other sources and/or IDEs

EOS
    end
  end

  desc "import", "download and install vendor imports"
  method_option :clean,  type: :boolean, aliases: '-c', default: false, desc: "clean cache first"
  method_option :sym,  type: :boolean, aliases: '-s', default: true, desc: "use symlinks"
  def import
    clean_vendor(options) if options.clean?
    prepare
    say "WARN: ensure your shared folder supports symlinks!!" if options.sym? && PRJ_IMPORTS.expand_path.mountpoint?
    silence_warnings{DSL.run_imports_dvm_script(PRJ_IMPORTS_FILE, options)}
  end

  desc "clean", "Clean vendor imports."
  def clean
    clean_vendor(options)
    prepare
  end

private

  def clean_vendor(opts)
    remove_dir(PRJ_IMPORTS)
  end

  def prepare
    empty_directory PRJ_IMPORTS
  end
end

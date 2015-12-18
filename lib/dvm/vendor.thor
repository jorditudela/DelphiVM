﻿class Vendor < BuildTarget
   desc 'clean', 'clean vendor products', for: :clean
   desc 'make',  'make vendor products', for: :make
   desc 'build', 'build vendor products', for: :build
   method_option :group,
                 type: :string, aliases: '-g',
                 default: configuration.build_args,
                 desc: 'Use BuildGroup',
                 for: :clean
   method_option :group,
                 type: :string,
                 aliases: '-g',
                 default: configuration.build_args,
                 desc: 'Use BuildGroup',
                 for: :make
   method_option :group,
                 type: :string,
                 aliases: '-g',
                 default: configuration.build_args,
                 desc: 'Use BuildGroup', for: :build

   desc 'init', 'create and initialize vendor directory'
   def init
     create_file(PRJ_IMPORTS_FILE, skip: true) do
       <<-EOS
      # sample imports file for delphivm

      # set source url
      source "my_imports_path"

      # can use environment vars anywhere
      # source "\#{ENV['IMPORTS_PATH']}"

      # set IDE version
      uses 'D150'

      # now, you can declare some imports

      import "FastReport", "4.13.1" do
        ide_install('dclfs15.bpl','dclfsADO15.bpl', 'dclfrxIBX15.bpl')
      end

      # or if we don't need ide install

      import "TurboPower", "7.0.0"

      # repeat for other sources and/or IDEs

      EOS
     end
   end

   desc 'import', 'download and install vendor imports'
   method_option :force, type: :boolean, aliases: '-f', default: false, desc: 'force download when already in local cache'
   method_option :reset, type: :boolean, aliases: '-r', default: false, desc: 'clean prj vendor before import'
   method_option :sym, type: :boolean, aliases: '-s', default: false, desc: 'use symlinks'
   def import(*idevers)
     ides_in_prj = IDEServices.idelist(:prj).map(&:to_s)
     idevers =  ides_in_prj if idevers.empty?
     idevers &= ides_in_prj
     say 'WARN: ensure your project folder supports symlinks!!' if options.sym?
     do_reset if options.reset?
     prepare
     silence_warnings do
       DSL.load_dvm_script(PRJ_IMPORTS_FILE, options.merge(idevers: idevers)).send :proccess
     end
   end

   desc 'reset', 'erase vendor imports.'
   def reset
     do_reset
     prepare
   end

   desc 'tree', 'show dependencs tree. Use after import'
   def tree
     silence_warnings do
       DSL.load_dvm_script(PRJ_IMPORTS_FILE).send :tree
     end
   end

   desc 'reg', 'IDE register vendor packages'
   def reg
     do_reg
   end

   protected

   def do_clean(idetag, cfg)
     do_build_action(idetag, cfg, 'Clean')
   end

   def do_make(idetag, cfg)
     do_build_action(idetag, cfg, 'Make')
   end

   def do_build(idetag, cfg)
     do_build_action(idetag, cfg, 'Build')
     do_reg
   end

   def do_reg
     silence_warnings do
       DSL.load_dvm_script(PRJ_IMPORTS_FILE).send :ide_register
     end
   end

   def do_reset
     remove_dir(PRJ_IMPORTS)
   end

   def prepare
     PRJ_IMPORTS.mkpath
   end

   def adjust_prj_paths(prj_paths, import)
     vendor_prj_paths = {}
     vendor_path = PRJ_IMPORTS.relative_path_from(PRJ_ROOT)
     prj_paths.each { |key, val| vendor_prj_paths[key] = "#{vendor_path}/#{import}/#{val}" }
     IDEServices.prj_paths(vendor_prj_paths)
   end

   def do_build_action(idetag, cfg, action)
     idetag = [idetag] unless idetag.is_a? Array
     cfg = {} unless cfg
     cfg['BuildGroup'] = options[:group] if options.group?
     script = DSL.load_dvm_script(PRJ_IMPORTS_FILE, options)
     ides_in_prj = IDEServices.idelist(:prj).map(&:to_s)
     ides_installed = IDEServices.idelist(:installed).map(&:to_s)
     prj_paths = IDEServices.prj_paths

     need_ides = script.imports.values.map(&:idevers).flatten.uniq
     need_ides &= idetag unless idetag.empty?
     missing_ides = need_ides - (ides_installed & need_ides)
     say_status(:WARN, "#{missing_ides} not installed!", :red) unless missing_ides.empty?

     script.imports.values.each do |import|
       adjust_prj_paths(prj_paths, import.lib_tag)
       use_ides = import.idevers & ides_in_prj
       use_ides &= idetag unless idetag.empty?
       use_ides &= ides_installed
       use_ides.each do |use_ide|
         ide = IDEServices.new(use_ide)
         ide.call_build_tool(action, cfg)
       end
     end
   end
end

#
# Cookbook Name:: grub
# Recipe:: default
#
# Copyright (C) 2014 Emmanuel Bretelle <chantra@debunut.org>
#
# All rights reserved - Do Not Redistribute
#

if not node.platform?('centos')
  Chef::Log.fatal("Unsupported platform #{node['platform']}")
end

kernels = Dir.entries('/lib/modules').select {|f| !File.directory? f}

root=nil
boot=nil
File.read('/etc/fstab').split("\n").each do |line|
    if line.start_with?('#') || line.strip() == ''
      next
    end
    tokens = line.split()
    if tokens[1] == '/'
      root=tokens[0]
    end
    if tokens[1] == '/boot'
      boot=tokens[0]
    end
end

def get_real_device(logical_name)
  if logical_name.start_with?('/dev/')
    return logical_name
  end
  tokens = logical_name.split('=')
  return File.realpath("/dev/disk/by-#{tokens[0].downcase}/#{tokens[1]}")
end

def grub_root_from_logical_name(logical_name)
  device = get_real_device(logical_name)
  dev = File.basename(device)
  dev_number = dev[2..2].ord - 'a'.ord
  part_number = dev[3..-1].to_i - 1
  return "(hd#{dev_number},#{part_number})"
end

grub_root = nil
Chef::Log.warn("#{boot} - #{root}")
if boot
  grub_root = grub_root_from_logical_name(boot)
else
  grub_root = grub_root_from_logical_name(root)
end

template '/boot/grub/grub.conf' do
  source 'grub.conf.erb'
  variables({
    :root => root,
    :boot => boot,
    :grub_root => grub_root,
    :kernels => kernels
  })
end

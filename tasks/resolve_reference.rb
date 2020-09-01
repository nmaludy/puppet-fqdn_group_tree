require_relative "../../ruby_task_helper/files/task_helper.rb"



class FqdnGroupTreeReference < TaskHelper
  def fqdn_to_groups(fqdn)
    fqdn_parts = fqdn.downcase.split('.')
    hostname = fqdn_parts.first
    hostname.split('-')
  end

  def target_to_groups_recursive(target, groups, t_groups, group_name='')
    if t_groups.size == 1
      if !groups.has_key?('targets')
        groups['targets'] = []
      end
      groups['targets'] << target
    else
      group_name += t_groups.first
      if !groups.has_key?(group_name)
        groups[group_name] = {}
      end
      target_to_groups_recursive(target, groups[group_name], t_groups.drop(1), group_name + '_')
    end
  end

  def groups_hash_to_array_recursive(groups_hash)
    groups_hash.map do |name, value|
      if value.has_key?('targets')
        {
          'name' => name,
          'targets' => value['targets']
        }
      else
        {
          'name' => name,
          'groups' => groups_hash_to_array_recursive(value)
        }
      end
    end
  end
  
  def task(**opts)
    targets = opts[:targets]
    groups = {}

    targets.each do |target|
      case target
      when String
        t_groups = fqdn_to_groups(target)
        target_to_groups_recursive(target, groups, t_groups)
      when Hash
        t_groups = fqdn_to_groups(target['name'])
        target_to_groups_recursive(target, groups, t_groups)
      end
    end

    groups_array = groups_hash_to_array_recursive(groups)
    { value: groups_array }
  end
end

if $PROGRAM_NAME == __FILE__
  FqdnGroupTreeReference.run
end

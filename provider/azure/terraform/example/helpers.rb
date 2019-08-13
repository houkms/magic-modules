require 'api/object'

module Provider
  module Azure
    module Terraform
      class Example < Api::Object
        module Helpers
          def get_example_properties_to_check(example_name, object)
            request = object.azure_sdk_definition.read.request
            param_props = object.all_user_properties.select{|p| p.azure_sdk_references.any?{|ref| request.has_key?(ref)}}
            params = param_props.map{|p| p.name.underscore}.to_set

            example = get_example_by_names(example_name)
            example_props = example.properties
              .reject do |pn, pv|
                params.include?(pn) || pn == 'location'
              end
              .transform_values do |v|
                v.is_a?(String) && !v.match(/\$\{.+\}/).nil? ? :AttrSet : v
              end
            flatten_example_properties_to_check(example_props, true)
          end

          def flatten_example_properties_to_check(properties, has_nested_item)
            return properties unless has_nested_item
            flat_properties = Hash.new
            has_nested_item = false
            properties.each do |pn, pv|
              if pv.is_a?(Hash)
                pv.each do |key, val|
                  flat_properties["#{pn}.#{key}"] = val
                  has_nested_item = true if val.is_a?(Hash) || val.is_a?(Array)
                end
              elsif pv.is_a?(Array)
                flat_properties["#{pn}.#"] = pv.length
                pv.each_index do |ind|
                  flat_properties["#{pn}.#{ind}"] = pv[ind]
                  has_nested_item = true if pv[ind].is_a?(Hash) || pv[ind].is_a?(Array)
                end
              else
                flat_properties[pn] = pv
              end
            end
            return flatten_example_properties_to_check(flat_properties, has_nested_item)
          end
        end
      end
    end
  end
end

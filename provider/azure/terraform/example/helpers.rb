# Copyright 2019 Microsoft Corp.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
                flat_properties["#{pn}.#"] = pv.empty? ? 0 : 1
                pv.each do |key, val|
                  flat_properties["#{pn}.0.#{key}"] = val
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

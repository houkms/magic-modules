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

module Provider
  module Azure
    module Terraform
      module Schema

        def go_type(property)
          if property.is_a?(Api::Type::Boolean)
            'bool'
          elsif property.is_a?(Api::Type::Enum) ||
                property.is_a?(Api::Type::String)
            'string'
          elsif property.is_a?(Api::Type::Integer)
            'int'
          elsif property.is_a?(Api::Type::Double)
            'float64'
          elsif property.is_a?(Api::Type::KeyValuePairs)
            'map[string]interface{}'
          elsif property.is_a?(Api::Type::Array) ||
                property.is_a?(Api::Type::NestedObject)
            '[]interface{}'
          else
            'interface{}'
          end
        end

        def go_empty_value(property)
          if property.is_a?(Api::Type::Enum) || property.is_a?(Api::Type::String)
            '""'
          else
            'nil'
          end
        end

        def expand_func(property)
          expand_funcs[property.class]
        end

        def expand_funcs
          {
            Api::Type::Boolean => 'utils.Bool',
            Api::Type::String => 'utils.String',
            Api::Type::Integer => 'utils.Int',
            Api::Type::Double => 'utils.Float',
            Api::Azure::Type::Location => "utils.String",
            Api::Azure::Type::Tags => 'tags.Expand',
            Api::Azure::Type::ResourceReference => "utils.String"
          }
        end

        def schema_property_template(property, is_data_source)
          return property.custom_schema_definition unless get_property_value(property, "custom_schema_definition", nil).nil?
          if property.is_a?(Api::Azure::Type::ResourceGroupName)
            !is_data_source ? 'templates/azure/terraform/schemas/resource_group_name.erb' : 'templates/azure/terraform/schemas/datasource_resource_group_name.erb'
          elsif property.is_a?(Api::Azure::Type::Location)
            !is_data_source ? 'templates/azure/terraform/schemas/location.erb' : 'templates/azure/terraform/schemas/datasource_location.erb'
          elsif property.is_a?(Api::Azure::Type::Tags)
            !is_data_source ? 'templates/azure/terraform/schemas/tags.erb' : 'templates/azure/terraform/schemas/datasource_tags.erb'
          elsif property.is_a?(Api::Type::Boolean) ||
                property.is_a?(Api::Type::Enum) ||
                property.is_a?(Api::Type::String) ||
                property.is_a?(Api::Type::Integer) ||
                property.is_a?(Api::Type::Double) ||
                property.is_a?(Api::Type::Array) ||
                property.is_a?(Api::Type::KeyValuePairs) ||
                property.is_a?(Api::Type::NestedObject) ||
                property.is_a?(Api::Azure::Type::ISO8601DateTime) ||
                property.is_a?(Api::Azure::Type::ISO8601Duration)
            'templates/azure/terraform/schemas/primitive.erb'
          else
            'templates/azure/terraform/schemas/unsupport.erb'
          end
        end

        def schema_property_get_template(property)
          return property.custom_schema_get unless get_property_value(property, "custom_schema_get", nil).nil?
          return 'templates/azure/terraform/schemas/hide_from_schema.erb' if get_property_value(property, "hide_from_schema", false)
          if property.is_a?(Api::Azure::Type::Location)
            'templates/azure/terraform/schemas/location_get.erb'
          elsif property.is_a?(Api::Azure::Type::BooleanEnum)
            'templates/azure/terraform/schemas/boolean_enum_get.erb'
          elsif property.is_a?(Api::Type::Boolean) ||
                property.is_a?(Api::Type::Enum) ||
                property.is_a?(Api::Type::String) ||
                property.is_a?(Api::Type::Integer) ||
                property.is_a?(Api::Type::Double) ||
                property.is_a?(Api::Type::Array) ||
                property.is_a?(Api::Type::KeyValuePairs) ||
                property.is_a?(Api::Type::NestedObject)
            'templates/azure/terraform/schemas/basic_get.erb'
          else
            'templates/azure/terraform/schemas/unsupport.erb'
          end
        end

        def schema_property_set_template(property)
          return property.custom_schema_set unless get_property_value(property, "custom_schema_set", nil).nil?
          return 'templates/azure/terraform/schemas/hide_from_schema.erb' if get_property_value(property, "hide_from_schema", false)
          if property.is_a?(Api::Azure::Type::Location)
            'templates/azure/terraform/schemas/location_set.erb'
          elsif property.is_a?(Api::Azure::Type::Tags)
            'templates/azure/terraform/schemas/tags_set.erb'
          elsif property.is_a?(Api::Azure::Type::BooleanEnum)
            'templates/azure/terraform/schemas/boolean_enum_set.erb'
          elsif property.is_a?(Api::Azure::Type::ISO8601DateTime) || property.is_a?(Api::Azure::Type::ISO8601Duration)
            'templates/azure/terraform/schemas/datetime_and_duration_set.erb'
          elsif property.is_a?(Api::Type::Boolean) ||
                property.is_a?(Api::Type::Enum) ||
                property.is_a?(Api::Type::String) ||
                property.is_a?(Api::Type::Integer) ||
                property.is_a?(Api::Type::Double)
            'templates/azure/terraform/schemas/basic_set.erb'
          elsif property.is_a?(Api::Type::Array) ||
                property.is_a?(Api::Type::NestedObject) ||
                property.is_a?(Api::Type::KeyValuePairs)
            return 'templates/azure/terraform/schemas/string_array_set.erb' if property.is_a?(Api::Type::Array) && (property.item_type.is_a?(Api::Type::String) ||
              property.item_type == "Api::Type::String" || property.item_type == "Api::Azure::Type::ResourceReference")
            return 'templates/azure/terraform/schemas/integer_array_set.erb' if property.is_a?(Api::Type::Array) && property.item_type == "Api::Type::Integer"
            return 'templates/azure/terraform/schemas/float_array_set.erb' if property.is_a?(Api::Type::Array) && property.item_type == "Api::Type::Double"
            return 'templates/azure/terraform/schemas/key_value_pairs_set.erb' if property.is_a?(Api::Type::KeyValuePairs)
            'templates/azure/terraform/schemas/flatten_set.erb'
          else
            'templates/azure/terraform/schemas/unsupport.erb'
          end
        end

      end
    end
  end
end

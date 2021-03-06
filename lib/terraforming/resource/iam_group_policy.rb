module Terraforming
  module Resource
    class IAMGroupPolicy
      include Terraforming::Util

      def self.tf(client = Aws::IAM::Client.new)
        self.new(client).tf
      end

      def self.tfstate(client = Aws::IAM::Client.new)
        self.new(client).tfstate
      end

      def initialize(client)
        @client = client
      end

      def tf
        apply_template(@client, "tf/iam_group_policy")
      end

      def tfstate
        resources = iam_group_policies.inject({}) do |result, policy|
          attributes = {
            "group" => policy.group_name,
            "id" => iam_group_policy_id_of(policy),
            "name" => policy.policy_name,
            "policy" => CGI.unescape(policy.policy_document)
          }
          result["aws_iam_group_policy.#{policy.policy_name}"] = {
            "type" => "aws_iam_group_policy",
            "primary" => {
              "id" => iam_group_policy_id_of(policy),
              "attributes" => attributes
            }
          }

          result
        end

        generate_tfstate(resources)
      end

      private

      def iam_groups
        @client.list_groups.groups
      end

      def iam_group_policy_id_of(policy)
        "#{policy.group_name}:#{policy.policy_name}"
      end

      def iam_group_policy_names_in(group)
        @client.list_group_policies(group_name: group.group_name).policy_names
      end

      def iam_group_policy_of(group, policy_name)
        @client.get_group_policy(group_name: group.group_name, policy_name: policy_name)
      end

      def iam_group_policies
        iam_groups.map do |group|
          iam_group_policy_names_in(group).map { |policy_name| iam_group_policy_of(group, policy_name) }
        end.flatten
      end
    end
  end
end

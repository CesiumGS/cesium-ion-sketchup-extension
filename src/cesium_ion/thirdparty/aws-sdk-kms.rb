# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

require_relative 'aws-sdk-core'
require_relative 'aws-sigv4'

module Cesium::IonExporter

module Aws::KMS
  module Types

    # Contains information about an alias.
    #
    # @!attribute [rw] alias_name
    #   String that contains the alias. This value begins with `alias/`.
    #   @return [String]
    #
    # @!attribute [rw] alias_arn
    #   String that contains the key ARN.
    #   @return [String]
    #
    # @!attribute [rw] target_key_id
    #   String that contains the key identifier referred to by the alias.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/AliasListEntry AWS API Documentation
    #
    class AliasListEntry < Struct.new(
      :alias_name,
      :alias_arn,
      :target_key_id)
      include Aws::Structure
    end

    # The request was rejected because it attempted to create a resource
    # that already exists.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/AlreadyExistsException AWS API Documentation
    #
    class AlreadyExistsException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass CancelKeyDeletionRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   The unique identifier for the customer master key (CMK) for which to
    #   cancel deletion.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CancelKeyDeletionRequest AWS API Documentation
    #
    class CancelKeyDeletionRequest < Struct.new(
      :key_id)
      include Aws::Structure
    end

    # @!attribute [rw] key_id
    #   The unique identifier of the master key for which deletion is
    #   canceled.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CancelKeyDeletionResponse AWS API Documentation
    #
    class CancelKeyDeletionResponse < Struct.new(
      :key_id)
      include Aws::Structure
    end

    # The request was rejected because the specified AWS CloudHSM cluster is
    # already associated with a custom key store or it shares a backup
    # history with a cluster that is associated with a custom key store.
    # Each custom key store must be associated with a different AWS CloudHSM
    # cluster.
    #
    # Clusters that share a backup history have the same cluster
    # certificate. To view the cluster certificate of a cluster, use the
    # [DescribeClusters][1] operation.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CloudHsmClusterInUseException AWS API Documentation
    #
    class CloudHsmClusterInUseException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the associated AWS CloudHSM cluster
    # did not meet the configuration requirements for a custom key store.
    #
    # * The cluster must be configured with private subnets in at least two
    #   different Availability Zones in the Region.
    #
    # * The [security group for the cluster][1]
    #   (cloudhsm-cluster-*&lt;cluster-id&gt;*-sg) must include inbound
    #   rules and outbound rules that allow TCP traffic on ports 2223-2225.
    #   The **Source** in the inbound rules and the **Destination** in the
    #   outbound rules must match the security group ID. These rules are set
    #   by default when you create the cluster. Do not delete or change
    #   them. To get information about a particular security group, use the
    #   [DescribeSecurityGroups][2] operation.
    #
    # * The cluster must contain at least as many HSMs as the operation
    #   requires. To add HSMs, use the AWS CloudHSM [CreateHsm][3]
    #   operation.
    #
    #   For the CreateCustomKeyStore, UpdateCustomKeyStore, and CreateKey
    #   operations, the AWS CloudHSM cluster must have at least two active
    #   HSMs, each in a different Availability Zone. For the
    #   ConnectCustomKeyStore operation, the AWS CloudHSM must contain at
    #   least one active HSM.
    #
    # For information about the requirements for an AWS CloudHSM cluster
    # that is associated with a custom key store, see [Assemble the
    # Prerequisites][4] in the *AWS Key Management Service Developer Guide*.
    # For information about creating a private subnet for an AWS CloudHSM
    # cluster, see [Create a Private Subnet][5] in the *AWS CloudHSM User
    # Guide*. For information about cluster security groups, see [Configure
    # a Default Security Group][1] in the <i> <i>AWS CloudHSM User Guide</i>
    # </i>.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/configure-sg.html
    # [2]: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSecurityGroups.html
    # [3]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore
    # [5]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/create-subnets.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CloudHsmClusterInvalidConfigurationException AWS API Documentation
    #
    class CloudHsmClusterInvalidConfigurationException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the AWS CloudHSM cluster that is
    # associated with the custom key store is not active. Initialize and
    # activate the cluster and try the command again. For detailed
    # instructions, see [Getting Started][1] in the *AWS CloudHSM User
    # Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/getting-started.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CloudHsmClusterNotActiveException AWS API Documentation
    #
    class CloudHsmClusterNotActiveException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because AWS KMS cannot find the AWS CloudHSM
    # cluster with the specified cluster ID. Retry the request with a
    # different cluster ID.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CloudHsmClusterNotFoundException AWS API Documentation
    #
    class CloudHsmClusterNotFoundException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the specified AWS CloudHSM cluster
    # has a different cluster certificate than the original cluster. You
    # cannot use the operation to specify an unrelated cluster.
    #
    # Specify a cluster that shares a backup history with the original
    # cluster. This includes clusters that were created from a backup of the
    # current cluster, and clusters that were created from the same backup
    # that produced the current cluster.
    #
    # Clusters that share a backup history have the same cluster
    # certificate. To view the cluster certificate of a cluster, use the
    # [DescribeClusters][1] operation.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CloudHsmClusterNotRelatedException AWS API Documentation
    #
    class CloudHsmClusterNotRelatedException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ConnectCustomKeyStoreRequest
    #   data as a hash:
    #
    #       {
    #         custom_key_store_id: "CustomKeyStoreIdType", # required
    #       }
    #
    # @!attribute [rw] custom_key_store_id
    #   Enter the key store ID of the custom key store that you want to
    #   connect. To find the ID of a custom key store, use the
    #   DescribeCustomKeyStores operation.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ConnectCustomKeyStoreRequest AWS API Documentation
    #
    class ConnectCustomKeyStoreRequest < Struct.new(
      :custom_key_store_id)
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ConnectCustomKeyStoreResponse AWS API Documentation
    #
    class ConnectCustomKeyStoreResponse < Aws::EmptyStructure; end

    # @note When making an API call, you may pass CreateAliasRequest
    #   data as a hash:
    #
    #       {
    #         alias_name: "AliasNameType", # required
    #         target_key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] alias_name
    #   Specifies the alias name. This value must begin with `alias/`
    #   followed by a name, such as `alias/ExampleAlias`. The alias name
    #   cannot begin with `alias/aws/`. The `alias/aws/` prefix is reserved
    #   for AWS managed CMKs.
    #   @return [String]
    #
    # @!attribute [rw] target_key_id
    #   Identifies the CMK to which the alias refers. Specify the key ID or
    #   the Amazon Resource Name (ARN) of the CMK. You cannot specify
    #   another alias. For help finding the key ID and ARN, see [Finding the
    #   Key ID and ARN][1] in the *AWS Key Management Service Developer
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/viewing-keys.html#find-cmk-id-arn
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateAliasRequest AWS API Documentation
    #
    class CreateAliasRequest < Struct.new(
      :alias_name,
      :target_key_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass CreateCustomKeyStoreRequest
    #   data as a hash:
    #
    #       {
    #         custom_key_store_name: "CustomKeyStoreNameType", # required
    #         cloud_hsm_cluster_id: "CloudHsmClusterIdType", # required
    #         trust_anchor_certificate: "TrustAnchorCertificateType", # required
    #         key_store_password: "KeyStorePasswordType", # required
    #       }
    #
    # @!attribute [rw] custom_key_store_name
    #   Specifies a friendly name for the custom key store. The name must be
    #   unique in your AWS account.
    #   @return [String]
    #
    # @!attribute [rw] cloud_hsm_cluster_id
    #   Identifies the AWS CloudHSM cluster for the custom key store. Enter
    #   the cluster ID of any active AWS CloudHSM cluster that is not
    #   already associated with a custom key store. To find the cluster ID,
    #   use the [DescribeClusters][1] operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #   @return [String]
    #
    # @!attribute [rw] trust_anchor_certificate
    #   Enter the content of the trust anchor certificate for the cluster.
    #   This is the content of the `customerCA.crt` file that you created
    #   when you [initialized the cluster][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/initialize-cluster.html
    #   @return [String]
    #
    # @!attribute [rw] key_store_password
    #   Enter the password of the [ `kmsuser` crypto user (CU) account][1]
    #   in the specified AWS CloudHSM cluster. AWS KMS logs into the cluster
    #   as this user to manage key material on your behalf.
    #
    #   This parameter tells AWS KMS the `kmsuser` account password; it does
    #   not change the password in the AWS CloudHSM cluster.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateCustomKeyStoreRequest AWS API Documentation
    #
    class CreateCustomKeyStoreRequest < Struct.new(
      :custom_key_store_name,
      :cloud_hsm_cluster_id,
      :trust_anchor_certificate,
      :key_store_password)
      include Aws::Structure
    end

    # @!attribute [rw] custom_key_store_id
    #   A unique identifier for the new custom key store.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateCustomKeyStoreResponse AWS API Documentation
    #
    class CreateCustomKeyStoreResponse < Struct.new(
      :custom_key_store_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass CreateGrantRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         grantee_principal: "PrincipalIdType", # required
    #         retiring_principal: "PrincipalIdType",
    #         operations: ["Decrypt"], # required, accepts Decrypt, Encrypt, GenerateDataKey, GenerateDataKeyWithoutPlaintext, ReEncryptFrom, ReEncryptTo, CreateGrant, RetireGrant, DescribeKey
    #         constraints: {
    #           encryption_context_subset: {
    #             "EncryptionContextKey" => "EncryptionContextValue",
    #           },
    #           encryption_context_equals: {
    #             "EncryptionContextKey" => "EncryptionContextValue",
    #           },
    #         },
    #         grant_tokens: ["GrantTokenType"],
    #         name: "GrantNameType",
    #       }
    #
    # @!attribute [rw] key_id
    #   The unique identifier for the customer master key (CMK) that the
    #   grant applies to.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] grantee_principal
    #   The principal that is given permission to perform the operations
    #   that the grant permits.
    #
    #   To specify the principal, use the [Amazon Resource Name (ARN)][1] of
    #   an AWS principal. Valid AWS principals include AWS accounts (root),
    #   IAM users, IAM roles, federated users, and assumed role users. For
    #   examples of the ARN syntax to use for specifying a principal, see
    #   [AWS Identity and Access Management (IAM)][2] in the Example ARNs
    #   section of the *AWS General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #   @return [String]
    #
    # @!attribute [rw] retiring_principal
    #   The principal that is given permission to retire the grant by using
    #   RetireGrant operation.
    #
    #   To specify the principal, use the [Amazon Resource Name (ARN)][1] of
    #   an AWS principal. Valid AWS principals include AWS accounts (root),
    #   IAM users, federated users, and assumed role users. For examples of
    #   the ARN syntax to use for specifying a principal, see [AWS Identity
    #   and Access Management (IAM)][2] in the Example ARNs section of the
    #   *AWS General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #   @return [String]
    #
    # @!attribute [rw] operations
    #   A list of operations that the grant permits.
    #   @return [Array<String>]
    #
    # @!attribute [rw] constraints
    #   Allows a cryptographic operation only when the encryption context
    #   matches or includes the encryption context specified in this
    #   structure. For more information about encryption context, see
    #   [Encryption Context][1] in the <i> <i>AWS Key Management Service
    #   Developer Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #   @return [Types::GrantConstraints]
    #
    # @!attribute [rw] grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #   @return [Array<String>]
    #
    # @!attribute [rw] name
    #   A friendly name for identifying the grant. Use this value to prevent
    #   the unintended creation of duplicate grants when retrying this
    #   request.
    #
    #   When this value is absent, all `CreateGrant` requests result in a
    #   new grant with a unique `GrantId` even if all the supplied
    #   parameters are identical. This can result in unintended duplicates
    #   when you retry the `CreateGrant` request.
    #
    #   When this value is present, you can retry a `CreateGrant` request
    #   with identical parameters; if the grant already exists, the original
    #   `GrantId` is returned without creating a new grant. Note that the
    #   returned grant token is unique with every `CreateGrant` request,
    #   even when a duplicate `GrantId` is returned. All grant tokens
    #   obtained in this way can be used interchangeably.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateGrantRequest AWS API Documentation
    #
    class CreateGrantRequest < Struct.new(
      :key_id,
      :grantee_principal,
      :retiring_principal,
      :operations,
      :constraints,
      :grant_tokens,
      :name)
      include Aws::Structure
    end

    # @!attribute [rw] grant_token
    #   The grant token.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #   @return [String]
    #
    # @!attribute [rw] grant_id
    #   The unique identifier for the grant.
    #
    #   You can use the `GrantId` in a subsequent RetireGrant or RevokeGrant
    #   operation.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateGrantResponse AWS API Documentation
    #
    class CreateGrantResponse < Struct.new(
      :grant_token,
      :grant_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass CreateKeyRequest
    #   data as a hash:
    #
    #       {
    #         policy: "PolicyType",
    #         description: "DescriptionType",
    #         key_usage: "ENCRYPT_DECRYPT", # accepts ENCRYPT_DECRYPT
    #         origin: "AWS_KMS", # accepts AWS_KMS, EXTERNAL, AWS_CLOUDHSM
    #         custom_key_store_id: "CustomKeyStoreIdType",
    #         bypass_policy_lockout_safety_check: false,
    #         tags: [
    #           {
    #             tag_key: "TagKeyType", # required
    #             tag_value: "TagValueType", # required
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] policy
    #   The key policy to attach to the CMK.
    #
    #   If you provide a key policy, it must meet the following criteria:
    #
    #   * If you don't set `BypassPolicyLockoutSafetyCheck` to true, the
    #     key policy must allow the principal that is making the `CreateKey`
    #     request to make a subsequent PutKeyPolicy request on the CMK. This
    #     reduces the risk that the CMK becomes unmanageable. For more
    #     information, refer to the scenario in the [Default Key Policy][1]
    #     section of the <i> <i>AWS Key Management Service Developer
    #     Guide</i> </i>.
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to AWS KMS. When you create a new AWS principal (for
    #     example, an IAM user or role), you might need to enforce a delay
    #     before including the new principal in a key policy because the new
    #     principal might not be immediately visible to AWS KMS. For more
    #     information, see [Changes that I make are not always immediately
    #     visible][2] in the *AWS Identity and Access Management User
    #     Guide*.
    #
    #   If you do not provide a key policy, AWS KMS attaches a default key
    #   policy to the CMK. For more information, see [Default Key Policy][3]
    #   in the *AWS Key Management Service Developer Guide*.
    #
    #   The key policy size limit is 32 kilobytes (32768 bytes).
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default
    #   @return [String]
    #
    # @!attribute [rw] description
    #   A description of the CMK.
    #
    #   Use a description that helps you decide whether the CMK is
    #   appropriate for a task.
    #   @return [String]
    #
    # @!attribute [rw] key_usage
    #   The cryptographic operations for which you can use the CMK. The only
    #   valid value is `ENCRYPT_DECRYPT`, which means you can use the CMK to
    #   encrypt and decrypt data.
    #   @return [String]
    #
    # @!attribute [rw] origin
    #   The source of the key material for the CMK. You cannot change the
    #   origin after you create the CMK.
    #
    #   The default is `AWS_KMS`, which means AWS KMS creates the key
    #   material in its own key store.
    #
    #   When the parameter value is `EXTERNAL`, AWS KMS creates a CMK
    #   without key material so that you can import key material from your
    #   existing key management infrastructure. For more information about
    #   importing key material into AWS KMS, see [Importing Key Material][1]
    #   in the *AWS Key Management Service Developer Guide*.
    #
    #   When the parameter value is `AWS_CLOUDHSM`, AWS KMS creates the CMK
    #   in an AWS KMS [custom key store][2] and creates its key material in
    #   the associated AWS CloudHSM cluster. You must also use the
    #   `CustomKeyStoreId` parameter to identify the custom key store.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #   @return [String]
    #
    # @!attribute [rw] custom_key_store_id
    #   Creates the CMK in the specified [custom key store][1] and the key
    #   material in its associated AWS CloudHSM cluster. To create a CMK in
    #   a custom key store, you must also specify the `Origin` parameter
    #   with a value of `AWS_CLOUDHSM`. The AWS CloudHSM cluster that is
    #   associated with the custom key store must have at least two active
    #   HSMs, each in a different Availability Zone in the Region.
    #
    #   To find the ID of a custom key store, use the
    #   DescribeCustomKeyStores operation.
    #
    #   The response includes the custom key store ID and the ID of the AWS
    #   CloudHSM cluster.
    #
    #   This operation is part of the [Custom Key Store feature][1] feature
    #   in AWS KMS, which combines the convenience and extensive integration
    #   of AWS KMS with the isolation and control of a single-tenant key
    #   store.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #   @return [String]
    #
    # @!attribute [rw] bypass_policy_lockout_safety_check
    #   A flag to indicate whether to bypass the key policy lockout safety
    #   check.
    #
    #   Setting this value to true increases the risk that the CMK becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, refer to the scenario in the [Default Key
    #   Policy][1] section in the <i> <i>AWS Key Management Service
    #   Developer Guide</i> </i>.
    #
    #   Use this parameter only when you include a policy in the request and
    #   you intend to prevent the principal that is making the request from
    #   making a subsequent PutKeyPolicy request on the CMK.
    #
    #   The default value is false.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #   @return [Boolean]
    #
    # @!attribute [rw] tags
    #   One or more tags. Each tag consists of a tag key and a tag value.
    #   Tag keys and tag values are both required, but tag values can be
    #   empty (null) strings.
    #
    #   Use this parameter to tag the CMK when it is created. Alternately,
    #   you can omit this parameter and instead tag the CMK after it is
    #   created using TagResource.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateKeyRequest AWS API Documentation
    #
    class CreateKeyRequest < Struct.new(
      :policy,
      :description,
      :key_usage,
      :origin,
      :custom_key_store_id,
      :bypass_policy_lockout_safety_check,
      :tags)
      include Aws::Structure
    end

    # @!attribute [rw] key_metadata
    #   Metadata associated with the CMK.
    #   @return [Types::KeyMetadata]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateKeyResponse AWS API Documentation
    #
    class CreateKeyResponse < Struct.new(
      :key_metadata)
      include Aws::Structure
    end

    # The request was rejected because the custom key store contains AWS KMS
    # customer master keys (CMKs). After verifying that you do not need to
    # use the CMKs, use the ScheduleKeyDeletion operation to delete the
    # CMKs. After they are deleted, you can delete the custom key store.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CustomKeyStoreHasCMKsException AWS API Documentation
    #
    class CustomKeyStoreHasCMKsException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because of the `ConnectionState` of the
    # custom key store. To get the `ConnectionState` of a custom key store,
    # use the DescribeCustomKeyStores operation.
    #
    # This exception is thrown under the following conditions:
    #
    # * You requested the CreateKey or GenerateRandom operation in a custom
    #   key store that is not connected. These operations are valid only
    #   when the custom key store `ConnectionState` is `CONNECTED`.
    #
    # * You requested the UpdateCustomKeyStore or DeleteCustomKeyStore
    #   operation on a custom key store that is not disconnected. This
    #   operation is valid only when the custom key store `ConnectionState`
    #   is `DISCONNECTED`.
    #
    # * You requested the ConnectCustomKeyStore operation on a custom key
    #   store with a `ConnectionState` of `DISCONNECTING` or `FAILED`. This
    #   operation is valid for all other `ConnectionState` values.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CustomKeyStoreInvalidStateException AWS API Documentation
    #
    class CustomKeyStoreInvalidStateException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the specified custom key store name
    # is already assigned to another custom key store in the account. Try
    # again with a custom key store name that is unique in the account.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CustomKeyStoreNameInUseException AWS API Documentation
    #
    class CustomKeyStoreNameInUseException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because AWS KMS cannot find a custom key
    # store with the specified key store name or ID.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CustomKeyStoreNotFoundException AWS API Documentation
    #
    class CustomKeyStoreNotFoundException < Struct.new(
      :message)
      include Aws::Structure
    end

    # Contains information about each custom key store in the custom key
    # store list.
    #
    # @!attribute [rw] custom_key_store_id
    #   A unique identifier for the custom key store.
    #   @return [String]
    #
    # @!attribute [rw] custom_key_store_name
    #   The user-specified friendly name for the custom key store.
    #   @return [String]
    #
    # @!attribute [rw] cloud_hsm_cluster_id
    #   A unique identifier for the AWS CloudHSM cluster that is associated
    #   with the custom key store.
    #   @return [String]
    #
    # @!attribute [rw] trust_anchor_certificate
    #   The trust anchor certificate of the associated AWS CloudHSM cluster.
    #   When you [initialize the cluster][1], you create this certificate
    #   and save it in the `customerCA.crt` file.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/initialize-cluster.html#sign-csr
    #   @return [String]
    #
    # @!attribute [rw] connection_state
    #   Indicates whether the custom key store is connected to its AWS
    #   CloudHSM cluster.
    #
    #   You can create and use CMKs in your custom key stores only when its
    #   connection state is `CONNECTED`.
    #
    #   The value is `DISCONNECTED` if the key store has never been
    #   connected or you use the DisconnectCustomKeyStore operation to
    #   disconnect it. If the value is `CONNECTED` but you are having
    #   trouble using the custom key store, make sure that its associated
    #   AWS CloudHSM cluster is active and contains at least one active HSM.
    #
    #   A value of `FAILED` indicates that an attempt to connect was
    #   unsuccessful. For help resolving a connection failure, see
    #   [Troubleshooting a Custom Key Store][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    #   @return [String]
    #
    # @!attribute [rw] connection_error_code
    #   Describes the connection error. Valid values are:
    #
    #   * `CLUSTER_NOT_FOUND` - AWS KMS cannot find the AWS CloudHSM cluster
    #     with the specified cluster ID.
    #
    #   * `INSUFFICIENT_CLOUDHSM_HSMS` - The associated AWS CloudHSM cluster
    #     does not contain any active HSMs. To connect a custom key store to
    #     its AWS CloudHSM cluster, the cluster must contain at least one
    #     active HSM.
    #
    #   * `INTERNAL_ERROR` - AWS KMS could not complete the request due to
    #     an internal error. Retry the request. For `ConnectCustomKeyStore`
    #     requests, disconnect the custom key store before trying to connect
    #     again.
    #
    #   * `INVALID_CREDENTIALS` - AWS KMS does not have the correct password
    #     for the `kmsuser` crypto user in the AWS CloudHSM cluster.
    #
    #   * `NETWORK_ERRORS` - Network errors are preventing AWS KMS from
    #     connecting to the custom key store.
    #
    #   * `USER_LOCKED_OUT` - The `kmsuser` CU account is locked out of the
    #     associated AWS CloudHSM cluster due to too many failed password
    #     attempts. Before you can connect your custom key store to its AWS
    #     CloudHSM cluster, you must change the `kmsuser` account password
    #     and update the password value for the custom key store.
    #
    #   For help with connection failures, see [Troubleshooting Custom Key
    #   Stores][1] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    #   @return [String]
    #
    # @!attribute [rw] creation_date
    #   The date and time when the custom key store was created.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CustomKeyStoresListEntry AWS API Documentation
    #
    class CustomKeyStoresListEntry < Struct.new(
      :custom_key_store_id,
      :custom_key_store_name,
      :cloud_hsm_cluster_id,
      :trust_anchor_certificate,
      :connection_state,
      :connection_error_code,
      :creation_date)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DecryptRequest
    #   data as a hash:
    #
    #       {
    #         ciphertext_blob: "data", # required
    #         encryption_context: {
    #           "EncryptionContextKey" => "EncryptionContextValue",
    #         },
    #         grant_tokens: ["GrantTokenType"],
    #       }
    #
    # @!attribute [rw] ciphertext_blob
    #   Ciphertext to be decrypted. The blob includes metadata.
    #   @return [String]
    #
    # @!attribute [rw] encryption_context
    #   The encryption context. If this was specified in the Encrypt
    #   function, it must be specified here or the decryption operation will
    #   fail. For more information, see [Encryption Context][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DecryptRequest AWS API Documentation
    #
    class DecryptRequest < Struct.new(
      :ciphertext_blob,
      :encryption_context,
      :grant_tokens)
      include Aws::Structure
    end

    # @!attribute [rw] key_id
    #   ARN of the key used to perform the decryption. This value is
    #   returned if no errors are encountered during the operation.
    #   @return [String]
    #
    # @!attribute [rw] plaintext
    #   Decrypted plaintext data. When you use the HTTP API or the AWS CLI,
    #   the value is Base64-encoded. Otherwise, it is not encoded.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DecryptResponse AWS API Documentation
    #
    class DecryptResponse < Struct.new(
      :key_id,
      :plaintext)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteAliasRequest
    #   data as a hash:
    #
    #       {
    #         alias_name: "AliasNameType", # required
    #       }
    #
    # @!attribute [rw] alias_name
    #   The alias to be deleted. The alias name must begin with `alias/`
    #   followed by the alias name, such as `alias/ExampleAlias`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteAliasRequest AWS API Documentation
    #
    class DeleteAliasRequest < Struct.new(
      :alias_name)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DeleteCustomKeyStoreRequest
    #   data as a hash:
    #
    #       {
    #         custom_key_store_id: "CustomKeyStoreIdType", # required
    #       }
    #
    # @!attribute [rw] custom_key_store_id
    #   Enter the ID of the custom key store you want to delete. To find the
    #   ID of a custom key store, use the DescribeCustomKeyStores operation.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteCustomKeyStoreRequest AWS API Documentation
    #
    class DeleteCustomKeyStoreRequest < Struct.new(
      :custom_key_store_id)
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteCustomKeyStoreResponse AWS API Documentation
    #
    class DeleteCustomKeyStoreResponse < Aws::EmptyStructure; end

    # @note When making an API call, you may pass DeleteImportedKeyMaterialRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   Identifies the CMK from which you are deleting imported key
    #   material. The `Origin` of the CMK must be `EXTERNAL`.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteImportedKeyMaterialRequest AWS API Documentation
    #
    class DeleteImportedKeyMaterialRequest < Struct.new(
      :key_id)
      include Aws::Structure
    end

    # The system timed out while trying to fulfill the request. The request
    # can be retried.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DependencyTimeoutException AWS API Documentation
    #
    class DependencyTimeoutException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DescribeCustomKeyStoresRequest
    #   data as a hash:
    #
    #       {
    #         custom_key_store_id: "CustomKeyStoreIdType",
    #         custom_key_store_name: "CustomKeyStoreNameType",
    #         limit: 1,
    #         marker: "MarkerType",
    #       }
    #
    # @!attribute [rw] custom_key_store_id
    #   Gets only information about the specified custom key store. Enter
    #   the key store ID.
    #
    #   By default, this operation gets information about all custom key
    #   stores in the account and region. To limit the output to a
    #   particular custom key store, you can use either the
    #   `CustomKeyStoreId` or `CustomKeyStoreName` parameter, but not both.
    #   @return [String]
    #
    # @!attribute [rw] custom_key_store_name
    #   Gets only information about the specified custom key store. Enter
    #   the friendly name of the custom key store.
    #
    #   By default, this operation gets information about all custom key
    #   stores in the account and region. To limit the output to a
    #   particular custom key store, you can use either the
    #   `CustomKeyStoreId` or `CustomKeyStoreName` parameter, but not both.
    #   @return [String]
    #
    # @!attribute [rw] limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #   @return [Integer]
    #
    # @!attribute [rw] marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeCustomKeyStoresRequest AWS API Documentation
    #
    class DescribeCustomKeyStoresRequest < Struct.new(
      :custom_key_store_id,
      :custom_key_store_name,
      :limit,
      :marker)
      include Aws::Structure
    end

    # @!attribute [rw] custom_key_stores
    #   Contains metadata about each custom key store.
    #   @return [Array<Types::CustomKeyStoresListEntry>]
    #
    # @!attribute [rw] next_marker
    #   When `Truncated` is true, this element is present and contains the
    #   value to use for the `Marker` parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] truncated
    #   A flag that indicates whether there are more items in the list. When
    #   this value is true, the list in this response is truncated. To get
    #   more items, pass the value of the `NextMarker` element in
    #   thisresponse to the `Marker` parameter in a subsequent request.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeCustomKeyStoresResponse AWS API Documentation
    #
    class DescribeCustomKeyStoresResponse < Struct.new(
      :custom_key_stores,
      :next_marker,
      :truncated)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DescribeKeyRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         grant_tokens: ["GrantTokenType"],
    #       }
    #
    # @!attribute [rw] key_id
    #   Describes the specified customer master key (CMK).
    #
    #   If you specify a predefined AWS alias (an AWS alias with no key ID),
    #   KMS associates the alias with an [AWS managed CMK][1] and returns
    #   its `KeyId` and `Arn` in the response.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must
    #   use the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    #   @return [String]
    #
    # @!attribute [rw] grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeKeyRequest AWS API Documentation
    #
    class DescribeKeyRequest < Struct.new(
      :key_id,
      :grant_tokens)
      include Aws::Structure
    end

    # @!attribute [rw] key_metadata
    #   Metadata associated with the key.
    #   @return [Types::KeyMetadata]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeKeyResponse AWS API Documentation
    #
    class DescribeKeyResponse < Struct.new(
      :key_metadata)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DisableKeyRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisableKeyRequest AWS API Documentation
    #
    class DisableKeyRequest < Struct.new(
      :key_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DisableKeyRotationRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisableKeyRotationRequest AWS API Documentation
    #
    class DisableKeyRotationRequest < Struct.new(
      :key_id)
      include Aws::Structure
    end

    # The request was rejected because the specified CMK is not enabled.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisabledException AWS API Documentation
    #
    class DisabledException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DisconnectCustomKeyStoreRequest
    #   data as a hash:
    #
    #       {
    #         custom_key_store_id: "CustomKeyStoreIdType", # required
    #       }
    #
    # @!attribute [rw] custom_key_store_id
    #   Enter the ID of the custom key store you want to disconnect. To find
    #   the ID of a custom key store, use the DescribeCustomKeyStores
    #   operation.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisconnectCustomKeyStoreRequest AWS API Documentation
    #
    class DisconnectCustomKeyStoreRequest < Struct.new(
      :custom_key_store_id)
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisconnectCustomKeyStoreResponse AWS API Documentation
    #
    class DisconnectCustomKeyStoreResponse < Aws::EmptyStructure; end

    # @note When making an API call, you may pass EnableKeyRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EnableKeyRequest AWS API Documentation
    #
    class EnableKeyRequest < Struct.new(
      :key_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass EnableKeyRotationRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EnableKeyRotationRequest AWS API Documentation
    #
    class EnableKeyRotationRequest < Struct.new(
      :key_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass EncryptRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         plaintext: "data", # required
    #         encryption_context: {
    #           "EncryptionContextKey" => "EncryptionContextValue",
    #         },
    #         grant_tokens: ["GrantTokenType"],
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must
    #   use the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #   @return [String]
    #
    # @!attribute [rw] plaintext
    #   Data to be encrypted.
    #   @return [String]
    #
    # @!attribute [rw] encryption_context
    #   Name-value pair that specifies the encryption context to be used for
    #   authenticated encryption. If used here, the same value must be
    #   supplied to the `Decrypt` API or decryption will fail. For more
    #   information, see [Encryption Context][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EncryptRequest AWS API Documentation
    #
    class EncryptRequest < Struct.new(
      :key_id,
      :plaintext,
      :encryption_context,
      :grant_tokens)
      include Aws::Structure
    end

    # @!attribute [rw] ciphertext_blob
    #   The encrypted plaintext. When you use the HTTP API or the AWS CLI,
    #   the value is Base64-encoded. Otherwise, it is not encoded.
    #   @return [String]
    #
    # @!attribute [rw] key_id
    #   The ID of the key used during encryption.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EncryptResponse AWS API Documentation
    #
    class EncryptResponse < Struct.new(
      :ciphertext_blob,
      :key_id)
      include Aws::Structure
    end

    # The request was rejected because the provided import token is expired.
    # Use GetParametersForImport to get a new import token and public key,
    # use the new public key to encrypt the key material, and then try the
    # request again.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ExpiredImportTokenException AWS API Documentation
    #
    class ExpiredImportTokenException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass GenerateDataKeyRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         encryption_context: {
    #           "EncryptionContextKey" => "EncryptionContextValue",
    #         },
    #         number_of_bytes: 1,
    #         key_spec: "AES_256", # accepts AES_256, AES_128
    #         grant_tokens: ["GrantTokenType"],
    #       }
    #
    # @!attribute [rw] key_id
    #   An identifier for the CMK that encrypts the data key.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must
    #   use the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #   @return [String]
    #
    # @!attribute [rw] encryption_context
    #   A set of key-value pairs that represents additional authenticated
    #   data.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] number_of_bytes
    #   The length of the data key in bytes. For example, use the value 64
    #   to generate a 512-bit data key (64 bytes is 512 bits). For common
    #   key lengths (128-bit and 256-bit symmetric keys), we recommend that
    #   you use the `KeySpec` field instead of this one.
    #   @return [Integer]
    #
    # @!attribute [rw] key_spec
    #   The length of the data key. Use `AES_128` to generate a 128-bit
    #   symmetric key, or `AES_256` to generate a 256-bit symmetric key.
    #   @return [String]
    #
    # @!attribute [rw] grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyRequest AWS API Documentation
    #
    class GenerateDataKeyRequest < Struct.new(
      :key_id,
      :encryption_context,
      :number_of_bytes,
      :key_spec,
      :grant_tokens)
      include Aws::Structure
    end

    # @!attribute [rw] ciphertext_blob
    #   The encrypted copy of the data key. When you use the HTTP API or the
    #   AWS CLI, the value is Base64-encoded. Otherwise, it is not encoded.
    #   @return [String]
    #
    # @!attribute [rw] plaintext
    #   The plaintext data key. When you use the HTTP API or the AWS CLI,
    #   the value is Base64-encoded. Otherwise, it is not encoded. Use this
    #   data key to encrypt your data outside of KMS. Then, remove it from
    #   memory as soon as possible.
    #   @return [String]
    #
    # @!attribute [rw] key_id
    #   The identifier of the CMK that encrypted the data key.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyResponse AWS API Documentation
    #
    class GenerateDataKeyResponse < Struct.new(
      :ciphertext_blob,
      :plaintext,
      :key_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass GenerateDataKeyWithoutPlaintextRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         encryption_context: {
    #           "EncryptionContextKey" => "EncryptionContextValue",
    #         },
    #         key_spec: "AES_256", # accepts AES_256, AES_128
    #         number_of_bytes: 1,
    #         grant_tokens: ["GrantTokenType"],
    #       }
    #
    # @!attribute [rw] key_id
    #   The identifier of the customer master key (CMK) that encrypts the
    #   data key.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must
    #   use the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #   @return [String]
    #
    # @!attribute [rw] encryption_context
    #   A set of key-value pairs that represents additional authenticated
    #   data.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] key_spec
    #   The length of the data key. Use `AES_128` to generate a 128-bit
    #   symmetric key, or `AES_256` to generate a 256-bit symmetric key.
    #   @return [String]
    #
    # @!attribute [rw] number_of_bytes
    #   The length of the data key in bytes. For example, use the value 64
    #   to generate a 512-bit data key (64 bytes is 512 bits). For common
    #   key lengths (128-bit and 256-bit symmetric keys), we recommend that
    #   you use the `KeySpec` field instead of this one.
    #   @return [Integer]
    #
    # @!attribute [rw] grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyWithoutPlaintextRequest AWS API Documentation
    #
    class GenerateDataKeyWithoutPlaintextRequest < Struct.new(
      :key_id,
      :encryption_context,
      :key_spec,
      :number_of_bytes,
      :grant_tokens)
      include Aws::Structure
    end

    # @!attribute [rw] ciphertext_blob
    #   The encrypted data key. When you use the HTTP API or the AWS CLI,
    #   the value is Base64-encoded. Otherwise, it is not encoded.
    #   @return [String]
    #
    # @!attribute [rw] key_id
    #   The identifier of the CMK that encrypted the data key.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyWithoutPlaintextResponse AWS API Documentation
    #
    class GenerateDataKeyWithoutPlaintextResponse < Struct.new(
      :ciphertext_blob,
      :key_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass GenerateRandomRequest
    #   data as a hash:
    #
    #       {
    #         number_of_bytes: 1,
    #         custom_key_store_id: "CustomKeyStoreIdType",
    #       }
    #
    # @!attribute [rw] number_of_bytes
    #   The length of the byte string.
    #   @return [Integer]
    #
    # @!attribute [rw] custom_key_store_id
    #   Generates the random byte string in the AWS CloudHSM cluster that is
    #   associated with the specified [custom key store][1]. To find the ID
    #   of a custom key store, use the DescribeCustomKeyStores operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateRandomRequest AWS API Documentation
    #
    class GenerateRandomRequest < Struct.new(
      :number_of_bytes,
      :custom_key_store_id)
      include Aws::Structure
    end

    # @!attribute [rw] plaintext
    #   The random byte string. When you use the HTTP API or the AWS CLI,
    #   the value is Base64-encoded. Otherwise, it is not encoded.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateRandomResponse AWS API Documentation
    #
    class GenerateRandomResponse < Struct.new(
      :plaintext)
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetKeyPolicyRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         policy_name: "PolicyNameType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] policy_name
    #   Specifies the name of the key policy. The only valid name is
    #   `default`. To get the names of key policies, use ListKeyPolicies.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyPolicyRequest AWS API Documentation
    #
    class GetKeyPolicyRequest < Struct.new(
      :key_id,
      :policy_name)
      include Aws::Structure
    end

    # @!attribute [rw] policy
    #   A key policy document in JSON format.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyPolicyResponse AWS API Documentation
    #
    class GetKeyPolicyResponse < Struct.new(
      :policy)
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetKeyRotationStatusRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyRotationStatusRequest AWS API Documentation
    #
    class GetKeyRotationStatusRequest < Struct.new(
      :key_id)
      include Aws::Structure
    end

    # @!attribute [rw] key_rotation_enabled
    #   A Boolean value that specifies whether key rotation is enabled.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyRotationStatusResponse AWS API Documentation
    #
    class GetKeyRotationStatusResponse < Struct.new(
      :key_rotation_enabled)
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetParametersForImportRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         wrapping_algorithm: "RSAES_PKCS1_V1_5", # required, accepts RSAES_PKCS1_V1_5, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256
    #         wrapping_key_spec: "RSA_2048", # required, accepts RSA_2048
    #       }
    #
    # @!attribute [rw] key_id
    #   The identifier of the CMK into which you will import key material.
    #   The CMK's `Origin` must be `EXTERNAL`.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] wrapping_algorithm
    #   The algorithm you will use to encrypt the key material before
    #   importing it with ImportKeyMaterial. For more information, see
    #   [Encrypt the Key Material][1] in the *AWS Key Management Service
    #   Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-encrypt-key-material.html
    #   @return [String]
    #
    # @!attribute [rw] wrapping_key_spec
    #   The type of wrapping key (public key) to return in the response.
    #   Only 2048-bit RSA public keys are supported.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetParametersForImportRequest AWS API Documentation
    #
    class GetParametersForImportRequest < Struct.new(
      :key_id,
      :wrapping_algorithm,
      :wrapping_key_spec)
      include Aws::Structure
    end

    # @!attribute [rw] key_id
    #   The identifier of the CMK to use in a subsequent ImportKeyMaterial
    #   request. This is the same CMK specified in the
    #   `GetParametersForImport` request.
    #   @return [String]
    #
    # @!attribute [rw] import_token
    #   The import token to send in a subsequent ImportKeyMaterial request.
    #   @return [String]
    #
    # @!attribute [rw] public_key
    #   The public key to use to encrypt the key material before importing
    #   it with ImportKeyMaterial.
    #   @return [String]
    #
    # @!attribute [rw] parameters_valid_to
    #   The time at which the import token and public key are no longer
    #   valid. After this time, you cannot use them to make an
    #   ImportKeyMaterial request and you must send another
    #   `GetParametersForImport` request to get new ones.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetParametersForImportResponse AWS API Documentation
    #
    class GetParametersForImportResponse < Struct.new(
      :key_id,
      :import_token,
      :public_key,
      :parameters_valid_to)
      include Aws::Structure
    end

    # Use this structure to allow cryptographic operations in the grant only
    # when the operation request includes the specified [encryption
    # context][1].
    #
    # AWS KMS applies the grant constraints only when the grant allows a
    # cryptographic operation that accepts an encryption context as input,
    # such as the following.
    #
    # * Encrypt
    #
    # * Decrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyWithoutPlaintext
    #
    # * ReEncrypt
    #
    # AWS KMS does not apply the grant constraints to other operations, such
    # as DescribeKey or ScheduleKeyDeletion.
    #
    # In a cryptographic operation, the encryption context in the decryption
    # operation must be an exact, case-sensitive match for the keys and
    # values in the encryption context of the encryption operation. Only the
    # order of the pairs can vary.
    #
    #  However, in a grant constraint, the key in each key-value pair is not
    # case sensitive, but the value is case sensitive.
    #
    #  To avoid confusion, do not use multiple encryption context pairs that
    # differ only by case. To require a fully case-sensitive encryption
    # context, use the `kms:EncryptionContext:` and
    # `kms:EncryptionContextKeys` conditions in an IAM or key policy. For
    # details, see [kms:EncryptionContext:][2] in the <i> <i>AWS Key
    # Management Service Developer Guide</i> </i>.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/policy-conditions.html#conditions-kms-encryption-context
    #
    # @note When making an API call, you may pass GrantConstraints
    #   data as a hash:
    #
    #       {
    #         encryption_context_subset: {
    #           "EncryptionContextKey" => "EncryptionContextValue",
    #         },
    #         encryption_context_equals: {
    #           "EncryptionContextKey" => "EncryptionContextValue",
    #         },
    #       }
    #
    # @!attribute [rw] encryption_context_subset
    #   A list of key-value pairs that must be included in the encryption
    #   context of the cryptographic operation request. The grant allows the
    #   cryptographic operation only when the encryption context in the
    #   request includes the key-value pairs specified in this constraint,
    #   although it can include additional key-value pairs.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] encryption_context_equals
    #   A list of key-value pairs that must match the encryption context in
    #   the cryptographic operation request. The grant allows the operation
    #   only when the encryption context in the request is the same as the
    #   encryption context specified in this constraint.
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GrantConstraints AWS API Documentation
    #
    class GrantConstraints < Struct.new(
      :encryption_context_subset,
      :encryption_context_equals)
      include Aws::Structure
    end

    # Contains information about an entry in a list of grants.
    #
    # @!attribute [rw] key_id
    #   The unique identifier for the customer master key (CMK) to which the
    #   grant applies.
    #   @return [String]
    #
    # @!attribute [rw] grant_id
    #   The unique identifier for the grant.
    #   @return [String]
    #
    # @!attribute [rw] name
    #   The friendly name that identifies the grant. If a name was provided
    #   in the CreateGrant request, that name is returned. Otherwise this
    #   value is null.
    #   @return [String]
    #
    # @!attribute [rw] creation_date
    #   The date and time when the grant was created.
    #   @return [Time]
    #
    # @!attribute [rw] grantee_principal
    #   The principal that receives the grant's permissions.
    #   @return [String]
    #
    # @!attribute [rw] retiring_principal
    #   The principal that can retire the grant.
    #   @return [String]
    #
    # @!attribute [rw] issuing_account
    #   The AWS account under which the grant was issued.
    #   @return [String]
    #
    # @!attribute [rw] operations
    #   The list of operations permitted by the grant.
    #   @return [Array<String>]
    #
    # @!attribute [rw] constraints
    #   A list of key-value pairs that must be present in the encryption
    #   context of certain subsequent operations that the grant allows.
    #   @return [Types::GrantConstraints]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GrantListEntry AWS API Documentation
    #
    class GrantListEntry < Struct.new(
      :key_id,
      :grant_id,
      :name,
      :creation_date,
      :grantee_principal,
      :retiring_principal,
      :issuing_account,
      :operations,
      :constraints)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ImportKeyMaterialRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         import_token: "data", # required
    #         encrypted_key_material: "data", # required
    #         valid_to: Time.now,
    #         expiration_model: "KEY_MATERIAL_EXPIRES", # accepts KEY_MATERIAL_EXPIRES, KEY_MATERIAL_DOES_NOT_EXPIRE
    #       }
    #
    # @!attribute [rw] key_id
    #   The identifier of the CMK to import the key material into. The
    #   CMK's `Origin` must be `EXTERNAL`.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] import_token
    #   The import token that you received in the response to a previous
    #   GetParametersForImport request. It must be from the same response
    #   that contained the public key that you used to encrypt the key
    #   material.
    #   @return [String]
    #
    # @!attribute [rw] encrypted_key_material
    #   The encrypted key material to import. It must be encrypted with the
    #   public key that you received in the response to a previous
    #   GetParametersForImport request, using the wrapping algorithm that
    #   you specified in that request.
    #   @return [String]
    #
    # @!attribute [rw] valid_to
    #   The time at which the imported key material expires. When the key
    #   material expires, AWS KMS deletes the key material and the CMK
    #   becomes unusable. You must omit this parameter when the
    #   `ExpirationModel` parameter is set to
    #   `KEY_MATERIAL_DOES_NOT_EXPIRE`. Otherwise it is required.
    #   @return [Time]
    #
    # @!attribute [rw] expiration_model
    #   Specifies whether the key material expires. The default is
    #   `KEY_MATERIAL_EXPIRES`, in which case you must include the `ValidTo`
    #   parameter. When this parameter is set to
    #   `KEY_MATERIAL_DOES_NOT_EXPIRE`, you must omit the `ValidTo`
    #   parameter.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ImportKeyMaterialRequest AWS API Documentation
    #
    class ImportKeyMaterialRequest < Struct.new(
      :key_id,
      :import_token,
      :encrypted_key_material,
      :valid_to,
      :expiration_model)
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ImportKeyMaterialResponse AWS API Documentation
    #
    class ImportKeyMaterialResponse < Aws::EmptyStructure; end

    # The request was rejected because the provided key material is invalid
    # or is not the same key material that was previously imported into this
    # customer master key (CMK).
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/IncorrectKeyMaterialException AWS API Documentation
    #
    class IncorrectKeyMaterialException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the trust anchor certificate in the
    # request is not the trust anchor certificate for the specified AWS
    # CloudHSM cluster.
    #
    # When you [initialize the cluster][1], you create the trust anchor
    # certificate and save it in the `customerCA.crt` file.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/initialize-cluster.html#sign-csr
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/IncorrectTrustAnchorException AWS API Documentation
    #
    class IncorrectTrustAnchorException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the specified alias name is not
    # valid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/InvalidAliasNameException AWS API Documentation
    #
    class InvalidAliasNameException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because a specified ARN, or an ARN in a key
    # policy, is not valid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/InvalidArnException AWS API Documentation
    #
    class InvalidArnException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the specified ciphertext, or
    # additional authenticated data incorporated into the ciphertext, such
    # as the encryption context, is corrupted, missing, or otherwise
    # invalid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/InvalidCiphertextException AWS API Documentation
    #
    class InvalidCiphertextException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the specified `GrantId` is not valid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/InvalidGrantIdException AWS API Documentation
    #
    class InvalidGrantIdException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the specified grant token is not
    # valid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/InvalidGrantTokenException AWS API Documentation
    #
    class InvalidGrantTokenException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the provided import token is invalid
    # or is associated with a different customer master key (CMK).
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/InvalidImportTokenException AWS API Documentation
    #
    class InvalidImportTokenException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the specified `KeySpec` value is not
    # valid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/InvalidKeyUsageException AWS API Documentation
    #
    class InvalidKeyUsageException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the marker that specifies where
    # pagination should next begin is not valid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/InvalidMarkerException AWS API Documentation
    #
    class InvalidMarkerException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because an internal exception occurred. The
    # request can be retried.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/KMSInternalException AWS API Documentation
    #
    class KMSInternalException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the state of the specified resource
    # is not valid for this request.
    #
    # For more information about how key state affects the use of a CMK, see
    # [How Key State Affects Use of a Customer Master Key][1] in the *AWS
    # Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/KMSInvalidStateException AWS API Documentation
    #
    class KMSInvalidStateException < Struct.new(
      :message)
      include Aws::Structure
    end

    # Contains information about each entry in the key list.
    #
    # @!attribute [rw] key_id
    #   Unique identifier of the key.
    #   @return [String]
    #
    # @!attribute [rw] key_arn
    #   ARN of the key.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/KeyListEntry AWS API Documentation
    #
    class KeyListEntry < Struct.new(
      :key_id,
      :key_arn)
      include Aws::Structure
    end

    # Contains metadata about a customer master key (CMK).
    #
    # This data type is used as a response element for the CreateKey and
    # DescribeKey operations.
    #
    # @!attribute [rw] aws_account_id
    #   The twelve-digit account ID of the AWS account that owns the CMK.
    #   @return [String]
    #
    # @!attribute [rw] key_id
    #   The globally unique identifier for the CMK.
    #   @return [String]
    #
    # @!attribute [rw] arn
    #   The Amazon Resource Name (ARN) of the CMK. For examples, see [AWS
    #   Key Management Service (AWS KMS)][1] in the Example ARNs section of
    #   the *AWS General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-kms
    #   @return [String]
    #
    # @!attribute [rw] creation_date
    #   The date and time when the CMK was created.
    #   @return [Time]
    #
    # @!attribute [rw] enabled
    #   Specifies whether the CMK is enabled. When `KeyState` is `Enabled`
    #   this value is true, otherwise it is false.
    #   @return [Boolean]
    #
    # @!attribute [rw] description
    #   The description of the CMK.
    #   @return [String]
    #
    # @!attribute [rw] key_usage
    #   The cryptographic operations for which you can use the CMK. The only
    #   valid value is `ENCRYPT_DECRYPT`, which means you can use the CMK to
    #   encrypt and decrypt data.
    #   @return [String]
    #
    # @!attribute [rw] key_state
    #   The state of the CMK.
    #
    #   For more information about how key state affects the use of a CMK,
    #   see [How Key State Affects the Use of a Customer Master Key][1] in
    #   the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #   @return [String]
    #
    # @!attribute [rw] deletion_date
    #   The date and time after which AWS KMS deletes the CMK. This value is
    #   present only when `KeyState` is `PendingDeletion`.
    #   @return [Time]
    #
    # @!attribute [rw] valid_to
    #   The time at which the imported key material expires. When the key
    #   material expires, AWS KMS deletes the key material and the CMK
    #   becomes unusable. This value is present only for CMKs whose `Origin`
    #   is `EXTERNAL` and whose `ExpirationModel` is `KEY_MATERIAL_EXPIRES`,
    #   otherwise this value is omitted.
    #   @return [Time]
    #
    # @!attribute [rw] origin
    #   The source of the CMK's key material. When this value is `AWS_KMS`,
    #   AWS KMS created the key material. When this value is `EXTERNAL`, the
    #   key material was imported from your existing key management
    #   infrastructure or the CMK lacks key material. When this value is
    #   `AWS_CLOUDHSM`, the key material was created in the AWS CloudHSM
    #   cluster associated with a custom key store.
    #   @return [String]
    #
    # @!attribute [rw] custom_key_store_id
    #   A unique identifier for the [custom key store][1] that contains the
    #   CMK. This value is present only when the CMK is created in a custom
    #   key store.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #   @return [String]
    #
    # @!attribute [rw] cloud_hsm_cluster_id
    #   The cluster ID of the AWS CloudHSM cluster that contains the key
    #   material for the CMK. When you create a CMK in a [custom key
    #   store][1], AWS KMS creates the key material for the CMK in the
    #   associated AWS CloudHSM cluster. This value is present only when the
    #   CMK is created in a custom key store.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #   @return [String]
    #
    # @!attribute [rw] expiration_model
    #   Specifies whether the CMK's key material expires. This value is
    #   present only when `Origin` is `EXTERNAL`, otherwise this value is
    #   omitted.
    #   @return [String]
    #
    # @!attribute [rw] key_manager
    #   The manager of the CMK. CMKs in your AWS account are either customer
    #   managed or AWS managed. For more information about the difference,
    #   see [Customer Master Keys][1] in the *AWS Key Management Service
    #   Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/KeyMetadata AWS API Documentation
    #
    class KeyMetadata < Struct.new(
      :aws_account_id,
      :key_id,
      :arn,
      :creation_date,
      :enabled,
      :description,
      :key_usage,
      :key_state,
      :deletion_date,
      :valid_to,
      :origin,
      :custom_key_store_id,
      :cloud_hsm_cluster_id,
      :expiration_model,
      :key_manager)
      include Aws::Structure
    end

    # The request was rejected because the specified CMK was not available.
    # The request can be retried.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/KeyUnavailableException AWS API Documentation
    #
    class KeyUnavailableException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because a limit was exceeded. For more
    # information, see [Limits][1] in the *AWS Key Management Service
    # Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/limits.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/LimitExceededException AWS API Documentation
    #
    class LimitExceededException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListAliasesRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType",
    #         limit: 1,
    #         marker: "MarkerType",
    #       }
    #
    # @!attribute [rw] key_id
    #   Lists only aliases that refer to the specified CMK. The value of
    #   this parameter can be the ID or Amazon Resource Name (ARN) of a CMK
    #   in the caller's account and region. You cannot use an alias name or
    #   alias ARN in this value.
    #
    #   This parameter is optional. If you omit it, `ListAliases` returns
    #   all aliases in the account and region.
    #   @return [String]
    #
    # @!attribute [rw] limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to
    #   50.
    #   @return [Integer]
    #
    # @!attribute [rw] marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListAliasesRequest AWS API Documentation
    #
    class ListAliasesRequest < Struct.new(
      :key_id,
      :limit,
      :marker)
      include Aws::Structure
    end

    # @!attribute [rw] aliases
    #   A list of aliases.
    #   @return [Array<Types::AliasListEntry>]
    #
    # @!attribute [rw] next_marker
    #   When `Truncated` is true, this element is present and contains the
    #   value to use for the `Marker` parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] truncated
    #   A flag that indicates whether there are more items in the list. When
    #   this value is true, the list in this response is truncated. To get
    #   more items, pass the value of the `NextMarker` element in
    #   thisresponse to the `Marker` parameter in a subsequent request.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListAliasesResponse AWS API Documentation
    #
    class ListAliasesResponse < Struct.new(
      :aliases,
      :next_marker,
      :truncated)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListGrantsRequest
    #   data as a hash:
    #
    #       {
    #         limit: 1,
    #         marker: "MarkerType",
    #         key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to
    #   50.
    #   @return [Integer]
    #
    # @!attribute [rw] marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #   @return [String]
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListGrantsRequest AWS API Documentation
    #
    class ListGrantsRequest < Struct.new(
      :limit,
      :marker,
      :key_id)
      include Aws::Structure
    end

    # @!attribute [rw] grants
    #   A list of grants.
    #   @return [Array<Types::GrantListEntry>]
    #
    # @!attribute [rw] next_marker
    #   When `Truncated` is true, this element is present and contains the
    #   value to use for the `Marker` parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] truncated
    #   A flag that indicates whether there are more items in the list. When
    #   this value is true, the list in this response is truncated. To get
    #   more items, pass the value of the `NextMarker` element in
    #   thisresponse to the `Marker` parameter in a subsequent request.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListGrantsResponse AWS API Documentation
    #
    class ListGrantsResponse < Struct.new(
      :grants,
      :next_marker,
      :truncated)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListKeyPoliciesRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         limit: 1,
    #         marker: "MarkerType",
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #
    #   Only one policy can be attached to a key.
    #   @return [Integer]
    #
    # @!attribute [rw] marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeyPoliciesRequest AWS API Documentation
    #
    class ListKeyPoliciesRequest < Struct.new(
      :key_id,
      :limit,
      :marker)
      include Aws::Structure
    end

    # @!attribute [rw] policy_names
    #   A list of key policy names. The only valid value is `default`.
    #   @return [Array<String>]
    #
    # @!attribute [rw] next_marker
    #   When `Truncated` is true, this element is present and contains the
    #   value to use for the `Marker` parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] truncated
    #   A flag that indicates whether there are more items in the list. When
    #   this value is true, the list in this response is truncated. To get
    #   more items, pass the value of the `NextMarker` element in
    #   thisresponse to the `Marker` parameter in a subsequent request.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeyPoliciesResponse AWS API Documentation
    #
    class ListKeyPoliciesResponse < Struct.new(
      :policy_names,
      :next_marker,
      :truncated)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListKeysRequest
    #   data as a hash:
    #
    #       {
    #         limit: 1,
    #         marker: "MarkerType",
    #       }
    #
    # @!attribute [rw] limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #   @return [Integer]
    #
    # @!attribute [rw] marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeysRequest AWS API Documentation
    #
    class ListKeysRequest < Struct.new(
      :limit,
      :marker)
      include Aws::Structure
    end

    # @!attribute [rw] keys
    #   A list of customer master keys (CMKs).
    #   @return [Array<Types::KeyListEntry>]
    #
    # @!attribute [rw] next_marker
    #   When `Truncated` is true, this element is present and contains the
    #   value to use for the `Marker` parameter in a subsequent request.
    #   @return [String]
    #
    # @!attribute [rw] truncated
    #   A flag that indicates whether there are more items in the list. When
    #   this value is true, the list in this response is truncated. To get
    #   more items, pass the value of the `NextMarker` element in
    #   thisresponse to the `Marker` parameter in a subsequent request.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeysResponse AWS API Documentation
    #
    class ListKeysResponse < Struct.new(
      :keys,
      :next_marker,
      :truncated)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListResourceTagsRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         limit: 1,
    #         marker: "MarkerType",
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 50, inclusive. If you do not include a value, it defaults to 50.
    #   @return [Integer]
    #
    # @!attribute [rw] marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    #   Do not attempt to construct this value. Use only the value of
    #   `NextMarker` from the truncated response you just received.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListResourceTagsRequest AWS API Documentation
    #
    class ListResourceTagsRequest < Struct.new(
      :key_id,
      :limit,
      :marker)
      include Aws::Structure
    end

    # @!attribute [rw] tags
    #   A list of tags. Each tag consists of a tag key and a tag value.
    #   @return [Array<Types::Tag>]
    #
    # @!attribute [rw] next_marker
    #   When `Truncated` is true, this element is present and contains the
    #   value to use for the `Marker` parameter in a subsequent request.
    #
    #   Do not assume or infer any information from this value.
    #   @return [String]
    #
    # @!attribute [rw] truncated
    #   A flag that indicates whether there are more items in the list. When
    #   this value is true, the list in this response is truncated. To get
    #   more items, pass the value of the `NextMarker` element in
    #   thisresponse to the `Marker` parameter in a subsequent request.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListResourceTagsResponse AWS API Documentation
    #
    class ListResourceTagsResponse < Struct.new(
      :tags,
      :next_marker,
      :truncated)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ListRetirableGrantsRequest
    #   data as a hash:
    #
    #       {
    #         limit: 1,
    #         marker: "MarkerType",
    #         retiring_principal: "PrincipalIdType", # required
    #       }
    #
    # @!attribute [rw] limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to
    #   50.
    #   @return [Integer]
    #
    # @!attribute [rw] marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #   @return [String]
    #
    # @!attribute [rw] retiring_principal
    #   The retiring principal for which to list grants.
    #
    #   To specify the retiring principal, use the [Amazon Resource Name
    #   (ARN)][1] of an AWS principal. Valid AWS principals include AWS
    #   accounts (root), IAM users, federated users, and assumed role users.
    #   For examples of the ARN syntax for specifying a principal, see [AWS
    #   Identity and Access Management (IAM)][2] in the Example ARNs section
    #   of the *Amazon Web Services General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListRetirableGrantsRequest AWS API Documentation
    #
    class ListRetirableGrantsRequest < Struct.new(
      :limit,
      :marker,
      :retiring_principal)
      include Aws::Structure
    end

    # The request was rejected because the specified policy is not
    # syntactically or semantically correct.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/MalformedPolicyDocumentException AWS API Documentation
    #
    class MalformedPolicyDocumentException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the specified entity or resource
    # could not be found.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/NotFoundException AWS API Documentation
    #
    class NotFoundException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass PutKeyPolicyRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         policy_name: "PolicyNameType", # required
    #         policy: "PolicyType", # required
    #         bypass_policy_lockout_safety_check: false,
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] policy_name
    #   The name of the key policy. The only valid value is `default`.
    #   @return [String]
    #
    # @!attribute [rw] policy
    #   The key policy to attach to the CMK.
    #
    #   The key policy must meet the following criteria:
    #
    #   * If you don't set `BypassPolicyLockoutSafetyCheck` to true, the
    #     key policy must allow the principal that is making the
    #     `PutKeyPolicy` request to make a subsequent `PutKeyPolicy` request
    #     on the CMK. This reduces the risk that the CMK becomes
    #     unmanageable. For more information, refer to the scenario in the
    #     [Default Key Policy][1] section of the *AWS Key Management Service
    #     Developer Guide*.
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to AWS KMS. When you create a new AWS principal (for
    #     example, an IAM user or role), you might need to enforce a delay
    #     before including the new principal in a key policy because the new
    #     principal might not be immediately visible to AWS KMS. For more
    #     information, see [Changes that I make are not always immediately
    #     visible][2] in the *AWS Identity and Access Management User
    #     Guide*.
    #
    #   The key policy size limit is 32 kilobytes (32768 bytes).
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #   @return [String]
    #
    # @!attribute [rw] bypass_policy_lockout_safety_check
    #   A flag to indicate whether to bypass the key policy lockout safety
    #   check.
    #
    #   Setting this value to true increases the risk that the CMK becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, refer to the scenario in the [Default Key
    #   Policy][1] section in the *AWS Key Management Service Developer
    #   Guide*.
    #
    #   Use this parameter only when you intend to prevent the principal
    #   that is making the request from making a subsequent `PutKeyPolicy`
    #   request on the CMK.
    #
    #   The default value is false.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/PutKeyPolicyRequest AWS API Documentation
    #
    class PutKeyPolicyRequest < Struct.new(
      :key_id,
      :policy_name,
      :policy,
      :bypass_policy_lockout_safety_check)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ReEncryptRequest
    #   data as a hash:
    #
    #       {
    #         ciphertext_blob: "data", # required
    #         source_encryption_context: {
    #           "EncryptionContextKey" => "EncryptionContextValue",
    #         },
    #         destination_key_id: "KeyIdType", # required
    #         destination_encryption_context: {
    #           "EncryptionContextKey" => "EncryptionContextValue",
    #         },
    #         grant_tokens: ["GrantTokenType"],
    #       }
    #
    # @!attribute [rw] ciphertext_blob
    #   Ciphertext of the data to reencrypt.
    #   @return [String]
    #
    # @!attribute [rw] source_encryption_context
    #   Encryption context used to encrypt and decrypt the data specified in
    #   the `CiphertextBlob` parameter.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] destination_key_id
    #   A unique identifier for the CMK that is used to reencrypt the data.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must
    #   use the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #   @return [String]
    #
    # @!attribute [rw] destination_encryption_context
    #   Encryption context to use when the data is reencrypted.
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ReEncryptRequest AWS API Documentation
    #
    class ReEncryptRequest < Struct.new(
      :ciphertext_blob,
      :source_encryption_context,
      :destination_key_id,
      :destination_encryption_context,
      :grant_tokens)
      include Aws::Structure
    end

    # @!attribute [rw] ciphertext_blob
    #   The reencrypted data. When you use the HTTP API or the AWS CLI, the
    #   value is Base64-encoded. Otherwise, it is not encoded.
    #   @return [String]
    #
    # @!attribute [rw] source_key_id
    #   Unique identifier of the CMK used to originally encrypt the data.
    #   @return [String]
    #
    # @!attribute [rw] key_id
    #   Unique identifier of the CMK used to reencrypt the data.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ReEncryptResponse AWS API Documentation
    #
    class ReEncryptResponse < Struct.new(
      :ciphertext_blob,
      :source_key_id,
      :key_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass RetireGrantRequest
    #   data as a hash:
    #
    #       {
    #         grant_token: "GrantTokenType",
    #         key_id: "KeyIdType",
    #         grant_id: "GrantIdType",
    #       }
    #
    # @!attribute [rw] grant_token
    #   Token that identifies the grant to be retired.
    #   @return [String]
    #
    # @!attribute [rw] key_id
    #   The Amazon Resource Name (ARN) of the CMK associated with the grant.
    #
    #   For example:
    #   `arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #   @return [String]
    #
    # @!attribute [rw] grant_id
    #   Unique identifier of the grant to retire. The grant ID is returned
    #   in the response to a `CreateGrant` operation.
    #
    #   * Grant ID Example -
    #     0123456789012345678901234567890123456789012345678901234567890123
    #
    #   ^
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RetireGrantRequest AWS API Documentation
    #
    class RetireGrantRequest < Struct.new(
      :grant_token,
      :key_id,
      :grant_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass RevokeGrantRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         grant_id: "GrantIdType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key associated with the
    #   grant.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] grant_id
    #   Identifier of the grant to be revoked.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RevokeGrantRequest AWS API Documentation
    #
    class RevokeGrantRequest < Struct.new(
      :key_id,
      :grant_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass ScheduleKeyDeletionRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         pending_window_in_days: 1,
    #       }
    #
    # @!attribute [rw] key_id
    #   The unique identifier of the customer master key (CMK) to delete.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] pending_window_in_days
    #   The waiting period, specified in number of days. After the waiting
    #   period ends, AWS KMS deletes the customer master key (CMK).
    #
    #   This value is optional. If you include a value, it must be between 7
    #   and 30, inclusive. If you do not include a value, it defaults to 30.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ScheduleKeyDeletionRequest AWS API Documentation
    #
    class ScheduleKeyDeletionRequest < Struct.new(
      :key_id,
      :pending_window_in_days)
      include Aws::Structure
    end

    # @!attribute [rw] key_id
    #   The unique identifier of the customer master key (CMK) for which
    #   deletion is scheduled.
    #   @return [String]
    #
    # @!attribute [rw] deletion_date
    #   The date and time after which AWS KMS deletes the customer master
    #   key (CMK).
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ScheduleKeyDeletionResponse AWS API Documentation
    #
    class ScheduleKeyDeletionResponse < Struct.new(
      :key_id,
      :deletion_date)
      include Aws::Structure
    end

    # A key-value pair. A tag consists of a tag key and a tag value. Tag
    # keys and tag values are both required, but tag values can be empty
    # (null) strings.
    #
    # For information about the rules that apply to tag keys and tag values,
    # see [User-Defined Tag Restrictions][1] in the *AWS Billing and Cost
    # Management User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html
    #
    # @note When making an API call, you may pass Tag
    #   data as a hash:
    #
    #       {
    #         tag_key: "TagKeyType", # required
    #         tag_value: "TagValueType", # required
    #       }
    #
    # @!attribute [rw] tag_key
    #   The key of the tag.
    #   @return [String]
    #
    # @!attribute [rw] tag_value
    #   The value of the tag.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Tag AWS API Documentation
    #
    class Tag < Struct.new(
      :tag_key,
      :tag_value)
      include Aws::Structure
    end

    # The request was rejected because one or more tags are not valid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/TagException AWS API Documentation
    #
    class TagException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass TagResourceRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         tags: [ # required
    #           {
    #             tag_key: "TagKeyType", # required
    #             tag_value: "TagValueType", # required
    #           },
    #         ],
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the CMK you are tagging.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   One or more tags. Each tag consists of a tag key and a tag value.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/TagResourceRequest AWS API Documentation
    #
    class TagResourceRequest < Struct.new(
      :key_id,
      :tags)
      include Aws::Structure
    end

    # The request was rejected because a specified parameter is not
    # supported or a specified resource is not valid for this operation.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UnsupportedOperationException AWS API Documentation
    #
    class UnsupportedOperationException < Struct.new(
      :message)
      include Aws::Structure
    end

    # @note When making an API call, you may pass UntagResourceRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         tag_keys: ["TagKeyType"], # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the CMK from which you are removing tags.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] tag_keys
    #   One or more tag keys. Specify only the tag keys, not the tag values.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UntagResourceRequest AWS API Documentation
    #
    class UntagResourceRequest < Struct.new(
      :key_id,
      :tag_keys)
      include Aws::Structure
    end

    # @note When making an API call, you may pass UpdateAliasRequest
    #   data as a hash:
    #
    #       {
    #         alias_name: "AliasNameType", # required
    #         target_key_id: "KeyIdType", # required
    #       }
    #
    # @!attribute [rw] alias_name
    #   Specifies the name of the alias to change. This value must begin
    #   with `alias/` followed by the alias name, such as
    #   `alias/ExampleAlias`.
    #   @return [String]
    #
    # @!attribute [rw] target_key_id
    #   Unique identifier of the customer master key (CMK) to be mapped to
    #   the alias. When the update operation completes, the alias will point
    #   to this CMK.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #
    #   To verify that the alias is mapped to the correct CMK, use
    #   ListAliases.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateAliasRequest AWS API Documentation
    #
    class UpdateAliasRequest < Struct.new(
      :alias_name,
      :target_key_id)
      include Aws::Structure
    end

    # @note When making an API call, you may pass UpdateCustomKeyStoreRequest
    #   data as a hash:
    #
    #       {
    #         custom_key_store_id: "CustomKeyStoreIdType", # required
    #         new_custom_key_store_name: "CustomKeyStoreNameType",
    #         key_store_password: "KeyStorePasswordType",
    #         cloud_hsm_cluster_id: "CloudHsmClusterIdType",
    #       }
    #
    # @!attribute [rw] custom_key_store_id
    #   Identifies the custom key store that you want to update. Enter the
    #   ID of the custom key store. To find the ID of a custom key store,
    #   use the DescribeCustomKeyStores operation.
    #   @return [String]
    #
    # @!attribute [rw] new_custom_key_store_name
    #   Changes the friendly name of the custom key store to the value that
    #   you specify. The custom key store name must be unique in the AWS
    #   account.
    #   @return [String]
    #
    # @!attribute [rw] key_store_password
    #   Enter the current password of the `kmsuser` crypto user (CU) in the
    #   AWS CloudHSM cluster that is associated with the custom key store.
    #
    #   This parameter tells AWS KMS the current password of the `kmsuser`
    #   crypto user (CU). It does not set or change the password of any
    #   users in the AWS CloudHSM cluster.
    #   @return [String]
    #
    # @!attribute [rw] cloud_hsm_cluster_id
    #   Associates the custom key store with a related AWS CloudHSM cluster.
    #
    #   Enter the cluster ID of the cluster that you used to create the
    #   custom key store or a cluster that shares a backup history and has
    #   the same cluster certificate as the original cluster. You cannot use
    #   this parameter to associate a custom key store with an unrelated
    #   cluster. In addition, the replacement cluster must [fulfill the
    #   requirements][1] for a cluster associated with a custom key store.
    #   To view the cluster certificate of a cluster, use the
    #   [DescribeClusters][2] operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore
    #   [2]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateCustomKeyStoreRequest AWS API Documentation
    #
    class UpdateCustomKeyStoreRequest < Struct.new(
      :custom_key_store_id,
      :new_custom_key_store_name,
      :key_store_password,
      :cloud_hsm_cluster_id)
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateCustomKeyStoreResponse AWS API Documentation
    #
    class UpdateCustomKeyStoreResponse < Aws::EmptyStructure; end

    # @note When making an API call, you may pass UpdateKeyDescriptionRequest
    #   data as a hash:
    #
    #       {
    #         key_id: "KeyIdType", # required
    #         description: "DescriptionType", # required
    #       }
    #
    # @!attribute [rw] key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or
    #   DescribeKey.
    #   @return [String]
    #
    # @!attribute [rw] description
    #   New description for the CMK.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateKeyDescriptionRequest AWS API Documentation
    #
    class UpdateKeyDescriptionRequest < Struct.new(
      :key_id,
      :description)
      include Aws::Structure
    end

  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::KMS
  # @api private
  module ClientApi

    include Seahorse::Model

    AWSAccountIdType = Shapes::StringShape.new(name: 'AWSAccountIdType')
    AlgorithmSpec = Shapes::StringShape.new(name: 'AlgorithmSpec')
    AliasList = Shapes::ListShape.new(name: 'AliasList')
    AliasListEntry = Shapes::StructureShape.new(name: 'AliasListEntry')
    AliasNameType = Shapes::StringShape.new(name: 'AliasNameType')
    AlreadyExistsException = Shapes::StructureShape.new(name: 'AlreadyExistsException')
    ArnType = Shapes::StringShape.new(name: 'ArnType')
    BooleanType = Shapes::BooleanShape.new(name: 'BooleanType')
    CancelKeyDeletionRequest = Shapes::StructureShape.new(name: 'CancelKeyDeletionRequest')
    CancelKeyDeletionResponse = Shapes::StructureShape.new(name: 'CancelKeyDeletionResponse')
    CiphertextType = Shapes::BlobShape.new(name: 'CiphertextType')
    CloudHsmClusterIdType = Shapes::StringShape.new(name: 'CloudHsmClusterIdType')
    CloudHsmClusterInUseException = Shapes::StructureShape.new(name: 'CloudHsmClusterInUseException')
    CloudHsmClusterInvalidConfigurationException = Shapes::StructureShape.new(name: 'CloudHsmClusterInvalidConfigurationException')
    CloudHsmClusterNotActiveException = Shapes::StructureShape.new(name: 'CloudHsmClusterNotActiveException')
    CloudHsmClusterNotFoundException = Shapes::StructureShape.new(name: 'CloudHsmClusterNotFoundException')
    CloudHsmClusterNotRelatedException = Shapes::StructureShape.new(name: 'CloudHsmClusterNotRelatedException')
    ConnectCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'ConnectCustomKeyStoreRequest')
    ConnectCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'ConnectCustomKeyStoreResponse')
    ConnectionErrorCodeType = Shapes::StringShape.new(name: 'ConnectionErrorCodeType')
    ConnectionStateType = Shapes::StringShape.new(name: 'ConnectionStateType')
    CreateAliasRequest = Shapes::StructureShape.new(name: 'CreateAliasRequest')
    CreateCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'CreateCustomKeyStoreRequest')
    CreateCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'CreateCustomKeyStoreResponse')
    CreateGrantRequest = Shapes::StructureShape.new(name: 'CreateGrantRequest')
    CreateGrantResponse = Shapes::StructureShape.new(name: 'CreateGrantResponse')
    CreateKeyRequest = Shapes::StructureShape.new(name: 'CreateKeyRequest')
    CreateKeyResponse = Shapes::StructureShape.new(name: 'CreateKeyResponse')
    CustomKeyStoreHasCMKsException = Shapes::StructureShape.new(name: 'CustomKeyStoreHasCMKsException')
    CustomKeyStoreIdType = Shapes::StringShape.new(name: 'CustomKeyStoreIdType')
    CustomKeyStoreInvalidStateException = Shapes::StructureShape.new(name: 'CustomKeyStoreInvalidStateException')
    CustomKeyStoreNameInUseException = Shapes::StructureShape.new(name: 'CustomKeyStoreNameInUseException')
    CustomKeyStoreNameType = Shapes::StringShape.new(name: 'CustomKeyStoreNameType')
    CustomKeyStoreNotFoundException = Shapes::StructureShape.new(name: 'CustomKeyStoreNotFoundException')
    CustomKeyStoresList = Shapes::ListShape.new(name: 'CustomKeyStoresList')
    CustomKeyStoresListEntry = Shapes::StructureShape.new(name: 'CustomKeyStoresListEntry')
    DataKeySpec = Shapes::StringShape.new(name: 'DataKeySpec')
    DateType = Shapes::TimestampShape.new(name: 'DateType')
    DecryptRequest = Shapes::StructureShape.new(name: 'DecryptRequest')
    DecryptResponse = Shapes::StructureShape.new(name: 'DecryptResponse')
    DeleteAliasRequest = Shapes::StructureShape.new(name: 'DeleteAliasRequest')
    DeleteCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'DeleteCustomKeyStoreRequest')
    DeleteCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'DeleteCustomKeyStoreResponse')
    DeleteImportedKeyMaterialRequest = Shapes::StructureShape.new(name: 'DeleteImportedKeyMaterialRequest')
    DependencyTimeoutException = Shapes::StructureShape.new(name: 'DependencyTimeoutException')
    DescribeCustomKeyStoresRequest = Shapes::StructureShape.new(name: 'DescribeCustomKeyStoresRequest')
    DescribeCustomKeyStoresResponse = Shapes::StructureShape.new(name: 'DescribeCustomKeyStoresResponse')
    DescribeKeyRequest = Shapes::StructureShape.new(name: 'DescribeKeyRequest')
    DescribeKeyResponse = Shapes::StructureShape.new(name: 'DescribeKeyResponse')
    DescriptionType = Shapes::StringShape.new(name: 'DescriptionType')
    DisableKeyRequest = Shapes::StructureShape.new(name: 'DisableKeyRequest')
    DisableKeyRotationRequest = Shapes::StructureShape.new(name: 'DisableKeyRotationRequest')
    DisabledException = Shapes::StructureShape.new(name: 'DisabledException')
    DisconnectCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'DisconnectCustomKeyStoreRequest')
    DisconnectCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'DisconnectCustomKeyStoreResponse')
    EnableKeyRequest = Shapes::StructureShape.new(name: 'EnableKeyRequest')
    EnableKeyRotationRequest = Shapes::StructureShape.new(name: 'EnableKeyRotationRequest')
    EncryptRequest = Shapes::StructureShape.new(name: 'EncryptRequest')
    EncryptResponse = Shapes::StructureShape.new(name: 'EncryptResponse')
    EncryptionContextKey = Shapes::StringShape.new(name: 'EncryptionContextKey')
    EncryptionContextType = Shapes::MapShape.new(name: 'EncryptionContextType')
    EncryptionContextValue = Shapes::StringShape.new(name: 'EncryptionContextValue')
    ErrorMessageType = Shapes::StringShape.new(name: 'ErrorMessageType')
    ExpirationModelType = Shapes::StringShape.new(name: 'ExpirationModelType')
    ExpiredImportTokenException = Shapes::StructureShape.new(name: 'ExpiredImportTokenException')
    GenerateDataKeyRequest = Shapes::StructureShape.new(name: 'GenerateDataKeyRequest')
    GenerateDataKeyResponse = Shapes::StructureShape.new(name: 'GenerateDataKeyResponse')
    GenerateDataKeyWithoutPlaintextRequest = Shapes::StructureShape.new(name: 'GenerateDataKeyWithoutPlaintextRequest')
    GenerateDataKeyWithoutPlaintextResponse = Shapes::StructureShape.new(name: 'GenerateDataKeyWithoutPlaintextResponse')
    GenerateRandomRequest = Shapes::StructureShape.new(name: 'GenerateRandomRequest')
    GenerateRandomResponse = Shapes::StructureShape.new(name: 'GenerateRandomResponse')
    GetKeyPolicyRequest = Shapes::StructureShape.new(name: 'GetKeyPolicyRequest')
    GetKeyPolicyResponse = Shapes::StructureShape.new(name: 'GetKeyPolicyResponse')
    GetKeyRotationStatusRequest = Shapes::StructureShape.new(name: 'GetKeyRotationStatusRequest')
    GetKeyRotationStatusResponse = Shapes::StructureShape.new(name: 'GetKeyRotationStatusResponse')
    GetParametersForImportRequest = Shapes::StructureShape.new(name: 'GetParametersForImportRequest')
    GetParametersForImportResponse = Shapes::StructureShape.new(name: 'GetParametersForImportResponse')
    GrantConstraints = Shapes::StructureShape.new(name: 'GrantConstraints')
    GrantIdType = Shapes::StringShape.new(name: 'GrantIdType')
    GrantList = Shapes::ListShape.new(name: 'GrantList')
    GrantListEntry = Shapes::StructureShape.new(name: 'GrantListEntry')
    GrantNameType = Shapes::StringShape.new(name: 'GrantNameType')
    GrantOperation = Shapes::StringShape.new(name: 'GrantOperation')
    GrantOperationList = Shapes::ListShape.new(name: 'GrantOperationList')
    GrantTokenList = Shapes::ListShape.new(name: 'GrantTokenList')
    GrantTokenType = Shapes::StringShape.new(name: 'GrantTokenType')
    ImportKeyMaterialRequest = Shapes::StructureShape.new(name: 'ImportKeyMaterialRequest')
    ImportKeyMaterialResponse = Shapes::StructureShape.new(name: 'ImportKeyMaterialResponse')
    IncorrectKeyMaterialException = Shapes::StructureShape.new(name: 'IncorrectKeyMaterialException')
    IncorrectTrustAnchorException = Shapes::StructureShape.new(name: 'IncorrectTrustAnchorException')
    InvalidAliasNameException = Shapes::StructureShape.new(name: 'InvalidAliasNameException')
    InvalidArnException = Shapes::StructureShape.new(name: 'InvalidArnException')
    InvalidCiphertextException = Shapes::StructureShape.new(name: 'InvalidCiphertextException')
    InvalidGrantIdException = Shapes::StructureShape.new(name: 'InvalidGrantIdException')
    InvalidGrantTokenException = Shapes::StructureShape.new(name: 'InvalidGrantTokenException')
    InvalidImportTokenException = Shapes::StructureShape.new(name: 'InvalidImportTokenException')
    InvalidKeyUsageException = Shapes::StructureShape.new(name: 'InvalidKeyUsageException')
    InvalidMarkerException = Shapes::StructureShape.new(name: 'InvalidMarkerException')
    KMSInternalException = Shapes::StructureShape.new(name: 'KMSInternalException')
    KMSInvalidStateException = Shapes::StructureShape.new(name: 'KMSInvalidStateException')
    KeyIdType = Shapes::StringShape.new(name: 'KeyIdType')
    KeyList = Shapes::ListShape.new(name: 'KeyList')
    KeyListEntry = Shapes::StructureShape.new(name: 'KeyListEntry')
    KeyManagerType = Shapes::StringShape.new(name: 'KeyManagerType')
    KeyMetadata = Shapes::StructureShape.new(name: 'KeyMetadata')
    KeyState = Shapes::StringShape.new(name: 'KeyState')
    KeyStorePasswordType = Shapes::StringShape.new(name: 'KeyStorePasswordType')
    KeyUnavailableException = Shapes::StructureShape.new(name: 'KeyUnavailableException')
    KeyUsageType = Shapes::StringShape.new(name: 'KeyUsageType')
    LimitExceededException = Shapes::StructureShape.new(name: 'LimitExceededException')
    LimitType = Shapes::IntegerShape.new(name: 'LimitType')
    ListAliasesRequest = Shapes::StructureShape.new(name: 'ListAliasesRequest')
    ListAliasesResponse = Shapes::StructureShape.new(name: 'ListAliasesResponse')
    ListGrantsRequest = Shapes::StructureShape.new(name: 'ListGrantsRequest')
    ListGrantsResponse = Shapes::StructureShape.new(name: 'ListGrantsResponse')
    ListKeyPoliciesRequest = Shapes::StructureShape.new(name: 'ListKeyPoliciesRequest')
    ListKeyPoliciesResponse = Shapes::StructureShape.new(name: 'ListKeyPoliciesResponse')
    ListKeysRequest = Shapes::StructureShape.new(name: 'ListKeysRequest')
    ListKeysResponse = Shapes::StructureShape.new(name: 'ListKeysResponse')
    ListResourceTagsRequest = Shapes::StructureShape.new(name: 'ListResourceTagsRequest')
    ListResourceTagsResponse = Shapes::StructureShape.new(name: 'ListResourceTagsResponse')
    ListRetirableGrantsRequest = Shapes::StructureShape.new(name: 'ListRetirableGrantsRequest')
    MalformedPolicyDocumentException = Shapes::StructureShape.new(name: 'MalformedPolicyDocumentException')
    MarkerType = Shapes::StringShape.new(name: 'MarkerType')
    NotFoundException = Shapes::StructureShape.new(name: 'NotFoundException')
    NumberOfBytesType = Shapes::IntegerShape.new(name: 'NumberOfBytesType')
    OriginType = Shapes::StringShape.new(name: 'OriginType')
    PendingWindowInDaysType = Shapes::IntegerShape.new(name: 'PendingWindowInDaysType')
    PlaintextType = Shapes::BlobShape.new(name: 'PlaintextType')
    PolicyNameList = Shapes::ListShape.new(name: 'PolicyNameList')
    PolicyNameType = Shapes::StringShape.new(name: 'PolicyNameType')
    PolicyType = Shapes::StringShape.new(name: 'PolicyType')
    PrincipalIdType = Shapes::StringShape.new(name: 'PrincipalIdType')
    PutKeyPolicyRequest = Shapes::StructureShape.new(name: 'PutKeyPolicyRequest')
    ReEncryptRequest = Shapes::StructureShape.new(name: 'ReEncryptRequest')
    ReEncryptResponse = Shapes::StructureShape.new(name: 'ReEncryptResponse')
    RetireGrantRequest = Shapes::StructureShape.new(name: 'RetireGrantRequest')
    RevokeGrantRequest = Shapes::StructureShape.new(name: 'RevokeGrantRequest')
    ScheduleKeyDeletionRequest = Shapes::StructureShape.new(name: 'ScheduleKeyDeletionRequest')
    ScheduleKeyDeletionResponse = Shapes::StructureShape.new(name: 'ScheduleKeyDeletionResponse')
    Tag = Shapes::StructureShape.new(name: 'Tag')
    TagException = Shapes::StructureShape.new(name: 'TagException')
    TagKeyList = Shapes::ListShape.new(name: 'TagKeyList')
    TagKeyType = Shapes::StringShape.new(name: 'TagKeyType')
    TagList = Shapes::ListShape.new(name: 'TagList')
    TagResourceRequest = Shapes::StructureShape.new(name: 'TagResourceRequest')
    TagValueType = Shapes::StringShape.new(name: 'TagValueType')
    TrustAnchorCertificateType = Shapes::StringShape.new(name: 'TrustAnchorCertificateType')
    UnsupportedOperationException = Shapes::StructureShape.new(name: 'UnsupportedOperationException')
    UntagResourceRequest = Shapes::StructureShape.new(name: 'UntagResourceRequest')
    UpdateAliasRequest = Shapes::StructureShape.new(name: 'UpdateAliasRequest')
    UpdateCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'UpdateCustomKeyStoreRequest')
    UpdateCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'UpdateCustomKeyStoreResponse')
    UpdateKeyDescriptionRequest = Shapes::StructureShape.new(name: 'UpdateKeyDescriptionRequest')
    WrappingKeySpec = Shapes::StringShape.new(name: 'WrappingKeySpec')

    AliasList.member = Shapes::ShapeRef.new(shape: AliasListEntry)

    AliasListEntry.add_member(:alias_name, Shapes::ShapeRef.new(shape: AliasNameType, location_name: "AliasName"))
    AliasListEntry.add_member(:alias_arn, Shapes::ShapeRef.new(shape: ArnType, location_name: "AliasArn"))
    AliasListEntry.add_member(:target_key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "TargetKeyId"))
    AliasListEntry.struct_class = Types::AliasListEntry

    AlreadyExistsException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    AlreadyExistsException.struct_class = Types::AlreadyExistsException

    CancelKeyDeletionRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    CancelKeyDeletionRequest.struct_class = Types::CancelKeyDeletionRequest

    CancelKeyDeletionResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    CancelKeyDeletionResponse.struct_class = Types::CancelKeyDeletionResponse

    CloudHsmClusterInUseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterInUseException.struct_class = Types::CloudHsmClusterInUseException

    CloudHsmClusterInvalidConfigurationException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterInvalidConfigurationException.struct_class = Types::CloudHsmClusterInvalidConfigurationException

    CloudHsmClusterNotActiveException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterNotActiveException.struct_class = Types::CloudHsmClusterNotActiveException

    CloudHsmClusterNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterNotFoundException.struct_class = Types::CloudHsmClusterNotFoundException

    CloudHsmClusterNotRelatedException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterNotRelatedException.struct_class = Types::CloudHsmClusterNotRelatedException

    ConnectCustomKeyStoreRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, required: true, location_name: "CustomKeyStoreId"))
    ConnectCustomKeyStoreRequest.struct_class = Types::ConnectCustomKeyStoreRequest

    ConnectCustomKeyStoreResponse.struct_class = Types::ConnectCustomKeyStoreResponse

    CreateAliasRequest.add_member(:alias_name, Shapes::ShapeRef.new(shape: AliasNameType, required: true, location_name: "AliasName"))
    CreateAliasRequest.add_member(:target_key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "TargetKeyId"))
    CreateAliasRequest.struct_class = Types::CreateAliasRequest

    CreateCustomKeyStoreRequest.add_member(:custom_key_store_name, Shapes::ShapeRef.new(shape: CustomKeyStoreNameType, required: true, location_name: "CustomKeyStoreName"))
    CreateCustomKeyStoreRequest.add_member(:cloud_hsm_cluster_id, Shapes::ShapeRef.new(shape: CloudHsmClusterIdType, required: true, location_name: "CloudHsmClusterId"))
    CreateCustomKeyStoreRequest.add_member(:trust_anchor_certificate, Shapes::ShapeRef.new(shape: TrustAnchorCertificateType, required: true, location_name: "TrustAnchorCertificate"))
    CreateCustomKeyStoreRequest.add_member(:key_store_password, Shapes::ShapeRef.new(shape: KeyStorePasswordType, required: true, location_name: "KeyStorePassword"))
    CreateCustomKeyStoreRequest.struct_class = Types::CreateCustomKeyStoreRequest

    CreateCustomKeyStoreResponse.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    CreateCustomKeyStoreResponse.struct_class = Types::CreateCustomKeyStoreResponse

    CreateGrantRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    CreateGrantRequest.add_member(:grantee_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, required: true, location_name: "GranteePrincipal"))
    CreateGrantRequest.add_member(:retiring_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "RetiringPrincipal"))
    CreateGrantRequest.add_member(:operations, Shapes::ShapeRef.new(shape: GrantOperationList, required: true, location_name: "Operations"))
    CreateGrantRequest.add_member(:constraints, Shapes::ShapeRef.new(shape: GrantConstraints, location_name: "Constraints"))
    CreateGrantRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    CreateGrantRequest.add_member(:name, Shapes::ShapeRef.new(shape: GrantNameType, location_name: "Name"))
    CreateGrantRequest.struct_class = Types::CreateGrantRequest

    CreateGrantResponse.add_member(:grant_token, Shapes::ShapeRef.new(shape: GrantTokenType, location_name: "GrantToken"))
    CreateGrantResponse.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, location_name: "GrantId"))
    CreateGrantResponse.struct_class = Types::CreateGrantResponse

    CreateKeyRequest.add_member(:policy, Shapes::ShapeRef.new(shape: PolicyType, location_name: "Policy"))
    CreateKeyRequest.add_member(:description, Shapes::ShapeRef.new(shape: DescriptionType, location_name: "Description"))
    CreateKeyRequest.add_member(:key_usage, Shapes::ShapeRef.new(shape: KeyUsageType, location_name: "KeyUsage"))
    CreateKeyRequest.add_member(:origin, Shapes::ShapeRef.new(shape: OriginType, location_name: "Origin"))
    CreateKeyRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    CreateKeyRequest.add_member(:bypass_policy_lockout_safety_check, Shapes::ShapeRef.new(shape: BooleanType, location_name: "BypassPolicyLockoutSafetyCheck"))
    CreateKeyRequest.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, location_name: "Tags"))
    CreateKeyRequest.struct_class = Types::CreateKeyRequest

    CreateKeyResponse.add_member(:key_metadata, Shapes::ShapeRef.new(shape: KeyMetadata, location_name: "KeyMetadata"))
    CreateKeyResponse.struct_class = Types::CreateKeyResponse

    CustomKeyStoreHasCMKsException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CustomKeyStoreHasCMKsException.struct_class = Types::CustomKeyStoreHasCMKsException

    CustomKeyStoreInvalidStateException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CustomKeyStoreInvalidStateException.struct_class = Types::CustomKeyStoreInvalidStateException

    CustomKeyStoreNameInUseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CustomKeyStoreNameInUseException.struct_class = Types::CustomKeyStoreNameInUseException

    CustomKeyStoreNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CustomKeyStoreNotFoundException.struct_class = Types::CustomKeyStoreNotFoundException

    CustomKeyStoresList.member = Shapes::ShapeRef.new(shape: CustomKeyStoresListEntry)

    CustomKeyStoresListEntry.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    CustomKeyStoresListEntry.add_member(:custom_key_store_name, Shapes::ShapeRef.new(shape: CustomKeyStoreNameType, location_name: "CustomKeyStoreName"))
    CustomKeyStoresListEntry.add_member(:cloud_hsm_cluster_id, Shapes::ShapeRef.new(shape: CloudHsmClusterIdType, location_name: "CloudHsmClusterId"))
    CustomKeyStoresListEntry.add_member(:trust_anchor_certificate, Shapes::ShapeRef.new(shape: TrustAnchorCertificateType, location_name: "TrustAnchorCertificate"))
    CustomKeyStoresListEntry.add_member(:connection_state, Shapes::ShapeRef.new(shape: ConnectionStateType, location_name: "ConnectionState"))
    CustomKeyStoresListEntry.add_member(:connection_error_code, Shapes::ShapeRef.new(shape: ConnectionErrorCodeType, location_name: "ConnectionErrorCode"))
    CustomKeyStoresListEntry.add_member(:creation_date, Shapes::ShapeRef.new(shape: DateType, location_name: "CreationDate"))
    CustomKeyStoresListEntry.struct_class = Types::CustomKeyStoresListEntry

    DecryptRequest.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "CiphertextBlob"))
    DecryptRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    DecryptRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    DecryptRequest.struct_class = Types::DecryptRequest

    DecryptResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    DecryptResponse.add_member(:plaintext, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "Plaintext"))
    DecryptResponse.struct_class = Types::DecryptResponse

    DeleteAliasRequest.add_member(:alias_name, Shapes::ShapeRef.new(shape: AliasNameType, required: true, location_name: "AliasName"))
    DeleteAliasRequest.struct_class = Types::DeleteAliasRequest

    DeleteCustomKeyStoreRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, required: true, location_name: "CustomKeyStoreId"))
    DeleteCustomKeyStoreRequest.struct_class = Types::DeleteCustomKeyStoreRequest

    DeleteCustomKeyStoreResponse.struct_class = Types::DeleteCustomKeyStoreResponse

    DeleteImportedKeyMaterialRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    DeleteImportedKeyMaterialRequest.struct_class = Types::DeleteImportedKeyMaterialRequest

    DependencyTimeoutException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    DependencyTimeoutException.struct_class = Types::DependencyTimeoutException

    DescribeCustomKeyStoresRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    DescribeCustomKeyStoresRequest.add_member(:custom_key_store_name, Shapes::ShapeRef.new(shape: CustomKeyStoreNameType, location_name: "CustomKeyStoreName"))
    DescribeCustomKeyStoresRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    DescribeCustomKeyStoresRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    DescribeCustomKeyStoresRequest.struct_class = Types::DescribeCustomKeyStoresRequest

    DescribeCustomKeyStoresResponse.add_member(:custom_key_stores, Shapes::ShapeRef.new(shape: CustomKeyStoresList, location_name: "CustomKeyStores"))
    DescribeCustomKeyStoresResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    DescribeCustomKeyStoresResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    DescribeCustomKeyStoresResponse.struct_class = Types::DescribeCustomKeyStoresResponse

    DescribeKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    DescribeKeyRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    DescribeKeyRequest.struct_class = Types::DescribeKeyRequest

    DescribeKeyResponse.add_member(:key_metadata, Shapes::ShapeRef.new(shape: KeyMetadata, location_name: "KeyMetadata"))
    DescribeKeyResponse.struct_class = Types::DescribeKeyResponse

    DisableKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    DisableKeyRequest.struct_class = Types::DisableKeyRequest

    DisableKeyRotationRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    DisableKeyRotationRequest.struct_class = Types::DisableKeyRotationRequest

    DisabledException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    DisabledException.struct_class = Types::DisabledException

    DisconnectCustomKeyStoreRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, required: true, location_name: "CustomKeyStoreId"))
    DisconnectCustomKeyStoreRequest.struct_class = Types::DisconnectCustomKeyStoreRequest

    DisconnectCustomKeyStoreResponse.struct_class = Types::DisconnectCustomKeyStoreResponse

    EnableKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    EnableKeyRequest.struct_class = Types::EnableKeyRequest

    EnableKeyRotationRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    EnableKeyRotationRequest.struct_class = Types::EnableKeyRotationRequest

    EncryptRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    EncryptRequest.add_member(:plaintext, Shapes::ShapeRef.new(shape: PlaintextType, required: true, location_name: "Plaintext"))
    EncryptRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    EncryptRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    EncryptRequest.struct_class = Types::EncryptRequest

    EncryptResponse.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextBlob"))
    EncryptResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    EncryptResponse.struct_class = Types::EncryptResponse

    EncryptionContextType.key = Shapes::ShapeRef.new(shape: EncryptionContextKey)
    EncryptionContextType.value = Shapes::ShapeRef.new(shape: EncryptionContextValue)

    ExpiredImportTokenException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    ExpiredImportTokenException.struct_class = Types::ExpiredImportTokenException

    GenerateDataKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GenerateDataKeyRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    GenerateDataKeyRequest.add_member(:number_of_bytes, Shapes::ShapeRef.new(shape: NumberOfBytesType, location_name: "NumberOfBytes"))
    GenerateDataKeyRequest.add_member(:key_spec, Shapes::ShapeRef.new(shape: DataKeySpec, location_name: "KeySpec"))
    GenerateDataKeyRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    GenerateDataKeyRequest.struct_class = Types::GenerateDataKeyRequest

    GenerateDataKeyResponse.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextBlob"))
    GenerateDataKeyResponse.add_member(:plaintext, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "Plaintext"))
    GenerateDataKeyResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GenerateDataKeyResponse.struct_class = Types::GenerateDataKeyResponse

    GenerateDataKeyWithoutPlaintextRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GenerateDataKeyWithoutPlaintextRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    GenerateDataKeyWithoutPlaintextRequest.add_member(:key_spec, Shapes::ShapeRef.new(shape: DataKeySpec, location_name: "KeySpec"))
    GenerateDataKeyWithoutPlaintextRequest.add_member(:number_of_bytes, Shapes::ShapeRef.new(shape: NumberOfBytesType, location_name: "NumberOfBytes"))
    GenerateDataKeyWithoutPlaintextRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    GenerateDataKeyWithoutPlaintextRequest.struct_class = Types::GenerateDataKeyWithoutPlaintextRequest

    GenerateDataKeyWithoutPlaintextResponse.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextBlob"))
    GenerateDataKeyWithoutPlaintextResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GenerateDataKeyWithoutPlaintextResponse.struct_class = Types::GenerateDataKeyWithoutPlaintextResponse

    GenerateRandomRequest.add_member(:number_of_bytes, Shapes::ShapeRef.new(shape: NumberOfBytesType, location_name: "NumberOfBytes"))
    GenerateRandomRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    GenerateRandomRequest.struct_class = Types::GenerateRandomRequest

    GenerateRandomResponse.add_member(:plaintext, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "Plaintext"))
    GenerateRandomResponse.struct_class = Types::GenerateRandomResponse

    GetKeyPolicyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GetKeyPolicyRequest.add_member(:policy_name, Shapes::ShapeRef.new(shape: PolicyNameType, required: true, location_name: "PolicyName"))
    GetKeyPolicyRequest.struct_class = Types::GetKeyPolicyRequest

    GetKeyPolicyResponse.add_member(:policy, Shapes::ShapeRef.new(shape: PolicyType, location_name: "Policy"))
    GetKeyPolicyResponse.struct_class = Types::GetKeyPolicyResponse

    GetKeyRotationStatusRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GetKeyRotationStatusRequest.struct_class = Types::GetKeyRotationStatusRequest

    GetKeyRotationStatusResponse.add_member(:key_rotation_enabled, Shapes::ShapeRef.new(shape: BooleanType, location_name: "KeyRotationEnabled"))
    GetKeyRotationStatusResponse.struct_class = Types::GetKeyRotationStatusResponse

    GetParametersForImportRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GetParametersForImportRequest.add_member(:wrapping_algorithm, Shapes::ShapeRef.new(shape: AlgorithmSpec, required: true, location_name: "WrappingAlgorithm"))
    GetParametersForImportRequest.add_member(:wrapping_key_spec, Shapes::ShapeRef.new(shape: WrappingKeySpec, required: true, location_name: "WrappingKeySpec"))
    GetParametersForImportRequest.struct_class = Types::GetParametersForImportRequest

    GetParametersForImportResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GetParametersForImportResponse.add_member(:import_token, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "ImportToken"))
    GetParametersForImportResponse.add_member(:public_key, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "PublicKey"))
    GetParametersForImportResponse.add_member(:parameters_valid_to, Shapes::ShapeRef.new(shape: DateType, location_name: "ParametersValidTo"))
    GetParametersForImportResponse.struct_class = Types::GetParametersForImportResponse

    GrantConstraints.add_member(:encryption_context_subset, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContextSubset"))
    GrantConstraints.add_member(:encryption_context_equals, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContextEquals"))
    GrantConstraints.struct_class = Types::GrantConstraints

    GrantList.member = Shapes::ShapeRef.new(shape: GrantListEntry)

    GrantListEntry.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GrantListEntry.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, location_name: "GrantId"))
    GrantListEntry.add_member(:name, Shapes::ShapeRef.new(shape: GrantNameType, location_name: "Name"))
    GrantListEntry.add_member(:creation_date, Shapes::ShapeRef.new(shape: DateType, location_name: "CreationDate"))
    GrantListEntry.add_member(:grantee_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "GranteePrincipal"))
    GrantListEntry.add_member(:retiring_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "RetiringPrincipal"))
    GrantListEntry.add_member(:issuing_account, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "IssuingAccount"))
    GrantListEntry.add_member(:operations, Shapes::ShapeRef.new(shape: GrantOperationList, location_name: "Operations"))
    GrantListEntry.add_member(:constraints, Shapes::ShapeRef.new(shape: GrantConstraints, location_name: "Constraints"))
    GrantListEntry.struct_class = Types::GrantListEntry

    GrantOperationList.member = Shapes::ShapeRef.new(shape: GrantOperation)

    GrantTokenList.member = Shapes::ShapeRef.new(shape: GrantTokenType)

    ImportKeyMaterialRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ImportKeyMaterialRequest.add_member(:import_token, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "ImportToken"))
    ImportKeyMaterialRequest.add_member(:encrypted_key_material, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "EncryptedKeyMaterial"))
    ImportKeyMaterialRequest.add_member(:valid_to, Shapes::ShapeRef.new(shape: DateType, location_name: "ValidTo"))
    ImportKeyMaterialRequest.add_member(:expiration_model, Shapes::ShapeRef.new(shape: ExpirationModelType, location_name: "ExpirationModel"))
    ImportKeyMaterialRequest.struct_class = Types::ImportKeyMaterialRequest

    ImportKeyMaterialResponse.struct_class = Types::ImportKeyMaterialResponse

    IncorrectKeyMaterialException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    IncorrectKeyMaterialException.struct_class = Types::IncorrectKeyMaterialException

    IncorrectTrustAnchorException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    IncorrectTrustAnchorException.struct_class = Types::IncorrectTrustAnchorException

    InvalidAliasNameException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidAliasNameException.struct_class = Types::InvalidAliasNameException

    InvalidArnException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidArnException.struct_class = Types::InvalidArnException

    InvalidCiphertextException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidCiphertextException.struct_class = Types::InvalidCiphertextException

    InvalidGrantIdException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidGrantIdException.struct_class = Types::InvalidGrantIdException

    InvalidGrantTokenException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidGrantTokenException.struct_class = Types::InvalidGrantTokenException

    InvalidImportTokenException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidImportTokenException.struct_class = Types::InvalidImportTokenException

    InvalidKeyUsageException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidKeyUsageException.struct_class = Types::InvalidKeyUsageException

    InvalidMarkerException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidMarkerException.struct_class = Types::InvalidMarkerException

    KMSInternalException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    KMSInternalException.struct_class = Types::KMSInternalException

    KMSInvalidStateException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    KMSInvalidStateException.struct_class = Types::KMSInvalidStateException

    KeyList.member = Shapes::ShapeRef.new(shape: KeyListEntry)

    KeyListEntry.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    KeyListEntry.add_member(:key_arn, Shapes::ShapeRef.new(shape: ArnType, location_name: "KeyArn"))
    KeyListEntry.struct_class = Types::KeyListEntry

    KeyMetadata.add_member(:aws_account_id, Shapes::ShapeRef.new(shape: AWSAccountIdType, location_name: "AWSAccountId"))
    KeyMetadata.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    KeyMetadata.add_member(:arn, Shapes::ShapeRef.new(shape: ArnType, location_name: "Arn"))
    KeyMetadata.add_member(:creation_date, Shapes::ShapeRef.new(shape: DateType, location_name: "CreationDate"))
    KeyMetadata.add_member(:enabled, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Enabled"))
    KeyMetadata.add_member(:description, Shapes::ShapeRef.new(shape: DescriptionType, location_name: "Description"))
    KeyMetadata.add_member(:key_usage, Shapes::ShapeRef.new(shape: KeyUsageType, location_name: "KeyUsage"))
    KeyMetadata.add_member(:key_state, Shapes::ShapeRef.new(shape: KeyState, location_name: "KeyState"))
    KeyMetadata.add_member(:deletion_date, Shapes::ShapeRef.new(shape: DateType, location_name: "DeletionDate"))
    KeyMetadata.add_member(:valid_to, Shapes::ShapeRef.new(shape: DateType, location_name: "ValidTo"))
    KeyMetadata.add_member(:origin, Shapes::ShapeRef.new(shape: OriginType, location_name: "Origin"))
    KeyMetadata.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    KeyMetadata.add_member(:cloud_hsm_cluster_id, Shapes::ShapeRef.new(shape: CloudHsmClusterIdType, location_name: "CloudHsmClusterId"))
    KeyMetadata.add_member(:expiration_model, Shapes::ShapeRef.new(shape: ExpirationModelType, location_name: "ExpirationModel"))
    KeyMetadata.add_member(:key_manager, Shapes::ShapeRef.new(shape: KeyManagerType, location_name: "KeyManager"))
    KeyMetadata.struct_class = Types::KeyMetadata

    KeyUnavailableException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    KeyUnavailableException.struct_class = Types::KeyUnavailableException

    LimitExceededException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    LimitExceededException.struct_class = Types::LimitExceededException

    ListAliasesRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    ListAliasesRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListAliasesRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListAliasesRequest.struct_class = Types::ListAliasesRequest

    ListAliasesResponse.add_member(:aliases, Shapes::ShapeRef.new(shape: AliasList, location_name: "Aliases"))
    ListAliasesResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListAliasesResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListAliasesResponse.struct_class = Types::ListAliasesResponse

    ListGrantsRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListGrantsRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListGrantsRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ListGrantsRequest.struct_class = Types::ListGrantsRequest

    ListGrantsResponse.add_member(:grants, Shapes::ShapeRef.new(shape: GrantList, location_name: "Grants"))
    ListGrantsResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListGrantsResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListGrantsResponse.struct_class = Types::ListGrantsResponse

    ListKeyPoliciesRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ListKeyPoliciesRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListKeyPoliciesRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListKeyPoliciesRequest.struct_class = Types::ListKeyPoliciesRequest

    ListKeyPoliciesResponse.add_member(:policy_names, Shapes::ShapeRef.new(shape: PolicyNameList, location_name: "PolicyNames"))
    ListKeyPoliciesResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListKeyPoliciesResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListKeyPoliciesResponse.struct_class = Types::ListKeyPoliciesResponse

    ListKeysRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListKeysRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListKeysRequest.struct_class = Types::ListKeysRequest

    ListKeysResponse.add_member(:keys, Shapes::ShapeRef.new(shape: KeyList, location_name: "Keys"))
    ListKeysResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListKeysResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListKeysResponse.struct_class = Types::ListKeysResponse

    ListResourceTagsRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ListResourceTagsRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListResourceTagsRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListResourceTagsRequest.struct_class = Types::ListResourceTagsRequest

    ListResourceTagsResponse.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, location_name: "Tags"))
    ListResourceTagsResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListResourceTagsResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListResourceTagsResponse.struct_class = Types::ListResourceTagsResponse

    ListRetirableGrantsRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListRetirableGrantsRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListRetirableGrantsRequest.add_member(:retiring_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, required: true, location_name: "RetiringPrincipal"))
    ListRetirableGrantsRequest.struct_class = Types::ListRetirableGrantsRequest

    MalformedPolicyDocumentException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    MalformedPolicyDocumentException.struct_class = Types::MalformedPolicyDocumentException

    NotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    NotFoundException.struct_class = Types::NotFoundException

    PolicyNameList.member = Shapes::ShapeRef.new(shape: PolicyNameType)

    PutKeyPolicyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    PutKeyPolicyRequest.add_member(:policy_name, Shapes::ShapeRef.new(shape: PolicyNameType, required: true, location_name: "PolicyName"))
    PutKeyPolicyRequest.add_member(:policy, Shapes::ShapeRef.new(shape: PolicyType, required: true, location_name: "Policy"))
    PutKeyPolicyRequest.add_member(:bypass_policy_lockout_safety_check, Shapes::ShapeRef.new(shape: BooleanType, location_name: "BypassPolicyLockoutSafetyCheck"))
    PutKeyPolicyRequest.struct_class = Types::PutKeyPolicyRequest

    ReEncryptRequest.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "CiphertextBlob"))
    ReEncryptRequest.add_member(:source_encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "SourceEncryptionContext"))
    ReEncryptRequest.add_member(:destination_key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "DestinationKeyId"))
    ReEncryptRequest.add_member(:destination_encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "DestinationEncryptionContext"))
    ReEncryptRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    ReEncryptRequest.struct_class = Types::ReEncryptRequest

    ReEncryptResponse.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextBlob"))
    ReEncryptResponse.add_member(:source_key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "SourceKeyId"))
    ReEncryptResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    ReEncryptResponse.struct_class = Types::ReEncryptResponse

    RetireGrantRequest.add_member(:grant_token, Shapes::ShapeRef.new(shape: GrantTokenType, location_name: "GrantToken"))
    RetireGrantRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    RetireGrantRequest.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, location_name: "GrantId"))
    RetireGrantRequest.struct_class = Types::RetireGrantRequest

    RevokeGrantRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    RevokeGrantRequest.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, required: true, location_name: "GrantId"))
    RevokeGrantRequest.struct_class = Types::RevokeGrantRequest

    ScheduleKeyDeletionRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ScheduleKeyDeletionRequest.add_member(:pending_window_in_days, Shapes::ShapeRef.new(shape: PendingWindowInDaysType, location_name: "PendingWindowInDays"))
    ScheduleKeyDeletionRequest.struct_class = Types::ScheduleKeyDeletionRequest

    ScheduleKeyDeletionResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    ScheduleKeyDeletionResponse.add_member(:deletion_date, Shapes::ShapeRef.new(shape: DateType, location_name: "DeletionDate"))
    ScheduleKeyDeletionResponse.struct_class = Types::ScheduleKeyDeletionResponse

    Tag.add_member(:tag_key, Shapes::ShapeRef.new(shape: TagKeyType, required: true, location_name: "TagKey"))
    Tag.add_member(:tag_value, Shapes::ShapeRef.new(shape: TagValueType, required: true, location_name: "TagValue"))
    Tag.struct_class = Types::Tag

    TagException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    TagException.struct_class = Types::TagException

    TagKeyList.member = Shapes::ShapeRef.new(shape: TagKeyType)

    TagList.member = Shapes::ShapeRef.new(shape: Tag)

    TagResourceRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    TagResourceRequest.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, required: true, location_name: "Tags"))
    TagResourceRequest.struct_class = Types::TagResourceRequest

    UnsupportedOperationException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    UnsupportedOperationException.struct_class = Types::UnsupportedOperationException

    UntagResourceRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    UntagResourceRequest.add_member(:tag_keys, Shapes::ShapeRef.new(shape: TagKeyList, required: true, location_name: "TagKeys"))
    UntagResourceRequest.struct_class = Types::UntagResourceRequest

    UpdateAliasRequest.add_member(:alias_name, Shapes::ShapeRef.new(shape: AliasNameType, required: true, location_name: "AliasName"))
    UpdateAliasRequest.add_member(:target_key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "TargetKeyId"))
    UpdateAliasRequest.struct_class = Types::UpdateAliasRequest

    UpdateCustomKeyStoreRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, required: true, location_name: "CustomKeyStoreId"))
    UpdateCustomKeyStoreRequest.add_member(:new_custom_key_store_name, Shapes::ShapeRef.new(shape: CustomKeyStoreNameType, location_name: "NewCustomKeyStoreName"))
    UpdateCustomKeyStoreRequest.add_member(:key_store_password, Shapes::ShapeRef.new(shape: KeyStorePasswordType, location_name: "KeyStorePassword"))
    UpdateCustomKeyStoreRequest.add_member(:cloud_hsm_cluster_id, Shapes::ShapeRef.new(shape: CloudHsmClusterIdType, location_name: "CloudHsmClusterId"))
    UpdateCustomKeyStoreRequest.struct_class = Types::UpdateCustomKeyStoreRequest

    UpdateCustomKeyStoreResponse.struct_class = Types::UpdateCustomKeyStoreResponse

    UpdateKeyDescriptionRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    UpdateKeyDescriptionRequest.add_member(:description, Shapes::ShapeRef.new(shape: DescriptionType, required: true, location_name: "Description"))
    UpdateKeyDescriptionRequest.struct_class = Types::UpdateKeyDescriptionRequest


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2014-11-01"

      api.metadata = {
        "apiVersion" => "2014-11-01",
        "endpointPrefix" => "kms",
        "jsonVersion" => "1.1",
        "protocol" => "json",
        "serviceAbbreviation" => "KMS",
        "serviceFullName" => "AWS Key Management Service",
        "serviceId" => "KMS",
        "signatureVersion" => "v4",
        "targetPrefix" => "TrentService",
        "uid" => "kms-2014-11-01",
      }

      api.add_operation(:cancel_key_deletion, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CancelKeyDeletion"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CancelKeyDeletionRequest)
        o.output = Shapes::ShapeRef.new(shape: CancelKeyDeletionResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:connect_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ConnectCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ConnectCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: ConnectCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotActiveException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInvalidConfigurationException)
      end)

      api.add_operation(:create_alias, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateAlias"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateAliasRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: AlreadyExistsException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidAliasNameException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:create_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInUseException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNameInUseException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotActiveException)
        o.errors << Shapes::ShapeRef.new(shape: IncorrectTrustAnchorException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInvalidConfigurationException)
      end)

      api.add_operation(:create_grant, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateGrant"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateGrantRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateGrantResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:create_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateKeyResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: TagException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInvalidConfigurationException)
      end)

      api.add_operation(:decrypt, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Decrypt"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DecryptRequest)
        o.output = Shapes::ShapeRef.new(shape: DecryptResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidCiphertextException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:delete_alias, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteAlias"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteAliasRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:delete_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: DeleteCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreHasCMKsException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
      end)

      api.add_operation(:delete_imported_key_material, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteImportedKeyMaterial"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteImportedKeyMaterialRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:describe_custom_key_stores, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DescribeCustomKeyStores"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DescribeCustomKeyStoresRequest)
        o.output = Shapes::ShapeRef.new(shape: DescribeCustomKeyStoresResponse)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
      end)

      api.add_operation(:describe_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DescribeKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DescribeKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: DescribeKeyResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
      end)

      api.add_operation(:disable_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DisableKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DisableKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:disable_key_rotation, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DisableKeyRotation"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DisableKeyRotationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:disconnect_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DisconnectCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DisconnectCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: DisconnectCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
      end)

      api.add_operation(:enable_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "EnableKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: EnableKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:enable_key_rotation, Seahorse::Model::Operation.new.tap do |o|
        o.name = "EnableKeyRotation"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: EnableKeyRotationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:encrypt, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Encrypt"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: EncryptRequest)
        o.output = Shapes::ShapeRef.new(shape: EncryptResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:generate_data_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateDataKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateDataKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateDataKeyResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:generate_data_key_without_plaintext, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateDataKeyWithoutPlaintext"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateDataKeyWithoutPlaintextRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateDataKeyWithoutPlaintextResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:generate_random, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateRandom"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateRandomRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateRandomResponse)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
      end)

      api.add_operation(:get_key_policy, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetKeyPolicy"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetKeyPolicyRequest)
        o.output = Shapes::ShapeRef.new(shape: GetKeyPolicyResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:get_key_rotation_status, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetKeyRotationStatus"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetKeyRotationStatusRequest)
        o.output = Shapes::ShapeRef.new(shape: GetKeyRotationStatusResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:get_parameters_for_import, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetParametersForImport"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetParametersForImportRequest)
        o.output = Shapes::ShapeRef.new(shape: GetParametersForImportResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:import_key_material, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ImportKeyMaterial"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ImportKeyMaterialRequest)
        o.output = Shapes::ShapeRef.new(shape: ImportKeyMaterialResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidCiphertextException)
        o.errors << Shapes::ShapeRef.new(shape: IncorrectKeyMaterialException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredImportTokenException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidImportTokenException)
      end)

      api.add_operation(:list_aliases, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListAliases"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListAliasesRequest)
        o.output = Shapes::ShapeRef.new(shape: ListAliasesResponse)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o[:pager] = Aws::Pager.new(
          more_results: "truncated",
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_grants, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListGrants"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListGrantsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListGrantsResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o[:pager] = Aws::Pager.new(
          more_results: "truncated",
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_key_policies, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListKeyPolicies"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListKeyPoliciesRequest)
        o.output = Shapes::ShapeRef.new(shape: ListKeyPoliciesResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o[:pager] = Aws::Pager.new(
          more_results: "truncated",
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_keys, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListKeys"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListKeysRequest)
        o.output = Shapes::ShapeRef.new(shape: ListKeysResponse)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o[:pager] = Aws::Pager.new(
          more_results: "truncated",
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_resource_tags, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListResourceTags"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListResourceTagsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListResourceTagsResponse)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
      end)

      api.add_operation(:list_retirable_grants, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListRetirableGrants"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListRetirableGrantsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListGrantsResponse)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
      end)

      api.add_operation(:put_key_policy, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutKeyPolicy"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: PutKeyPolicyRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:re_encrypt, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ReEncrypt"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ReEncryptRequest)
        o.output = Shapes::ShapeRef.new(shape: ReEncryptResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidCiphertextException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:retire_grant, Seahorse::Model::Operation.new.tap do |o|
        o.name = "RetireGrant"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: RetireGrantRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantIdException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:revoke_grant, Seahorse::Model::Operation.new.tap do |o|
        o.name = "RevokeGrant"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: RevokeGrantRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantIdException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:schedule_key_deletion, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ScheduleKeyDeletion"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ScheduleKeyDeletionRequest)
        o.output = Shapes::ShapeRef.new(shape: ScheduleKeyDeletionResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:tag_resource, Seahorse::Model::Operation.new.tap do |o|
        o.name = "TagResource"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: TagResourceRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: TagException)
      end)

      api.add_operation(:untag_resource, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UntagResource"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UntagResourceRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: TagException)
      end)

      api.add_operation(:update_alias, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UpdateAlias"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UpdateAliasRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:update_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UpdateCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UpdateCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: UpdateCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotRelatedException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotActiveException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInvalidConfigurationException)
      end)

      api.add_operation(:update_key_description, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UpdateKeyDescription"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UpdateKeyDescriptionRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)
    end

  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

# require 'seahorse/client/plugins/content_length.rb'
# require 'aws-sdk-core/plugins/credentials_configuration.rb'
# require 'aws-sdk-core/plugins/logging.rb'
# require 'aws-sdk-core/plugins/param_converter.rb'
# require 'aws-sdk-core/plugins/param_validator.rb'
# require 'aws-sdk-core/plugins/user_agent.rb'
# require 'aws-sdk-core/plugins/helpful_socket_errors.rb'
# require 'aws-sdk-core/plugins/retry_errors.rb'
# require 'aws-sdk-core/plugins/global_configuration.rb'
# require 'aws-sdk-core/plugins/regional_endpoint.rb'
# require 'aws-sdk-core/plugins/endpoint_discovery.rb'
# require 'aws-sdk-core/plugins/endpoint_pattern.rb'
# require 'aws-sdk-core/plugins/response_paging.rb'
# require 'aws-sdk-core/plugins/stub_responses.rb'
# require 'aws-sdk-core/plugins/idempotency_token.rb'
# require 'aws-sdk-core/plugins/jsonvalue_converter.rb'
# require 'aws-sdk-core/plugins/client_metrics_plugin.rb'
# require 'aws-sdk-core/plugins/client_metrics_send_plugin.rb'
# require 'aws-sdk-core/plugins/transfer_encoding.rb'
# require 'aws-sdk-core/plugins/signature_v4.rb'
# require 'aws-sdk-core/plugins/protocols/json_rpc.rb'

Aws::Plugins::GlobalConfiguration.add_identifier(:kms)

module Aws::KMS
  class Client < Seahorse::Client::Base

    include Aws::ClientStubs

    @identifier = :kms

    set_api(ClientApi::API)

    add_plugin(Seahorse::Client::Plugins::ContentLength)
    add_plugin(Aws::Plugins::CredentialsConfiguration)
    add_plugin(Aws::Plugins::Logging)
    add_plugin(Aws::Plugins::ParamConverter)
    add_plugin(Aws::Plugins::ParamValidator)
    add_plugin(Aws::Plugins::UserAgent)
    add_plugin(Aws::Plugins::HelpfulSocketErrors)
    add_plugin(Aws::Plugins::RetryErrors)
    add_plugin(Aws::Plugins::GlobalConfiguration)
    add_plugin(Aws::Plugins::RegionalEndpoint)
    add_plugin(Aws::Plugins::EndpointDiscovery)
    add_plugin(Aws::Plugins::EndpointPattern)
    add_plugin(Aws::Plugins::ResponsePaging)
    add_plugin(Aws::Plugins::StubResponses)
    add_plugin(Aws::Plugins::IdempotencyToken)
    add_plugin(Aws::Plugins::JsonvalueConverter)
    add_plugin(Aws::Plugins::ClientMetricsPlugin)
    add_plugin(Aws::Plugins::ClientMetricsSendPlugin)
    add_plugin(Aws::Plugins::TransferEncoding)
    add_plugin(Aws::Plugins::SignatureV4)
    add_plugin(Aws::Plugins::Protocols::JsonRpc)

    # @overload initialize(options)
    #   @param [Hash] options
    #   @option options [required, Aws::CredentialProvider] :credentials
    #     Your AWS credentials. This can be an instance of any one of the
    #     following classes:
    #
    #     * `Aws::Credentials` - Used for configuring static, non-refreshing
    #       credentials.
    #
    #     * `Aws::InstanceProfileCredentials` - Used for loading credentials
    #       from an EC2 IMDS on an EC2 instance.
    #
    #     * `Aws::SharedCredentials` - Used for loading credentials from a
    #       shared file, such as `~/.aws/config`.
    #
    #     * `Aws::AssumeRoleCredentials` - Used when you need to assume a role.
    #
    #     When `:credentials` are not configured directly, the following
    #     locations will be searched for credentials:
    #
    #     * `Aws.config[:credentials]`
    #     * The `:access_key_id`, `:secret_access_key`, and `:session_token` options.
    #     * ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #     * EC2 IMDS instance profile - When used by default, the timeouts are
    #       very aggressive. Construct and pass an instance of
    #       `Aws::InstanceProfileCredentails` to enable retries and extended
    #       timeouts.
    #
    #   @option options [required, String] :region
    #     The AWS region to connect to.  The configured `:region` is
    #     used to determine the service `:endpoint`. When not passed,
    #     a default `:region` is search for in the following locations:
    #
    #     * `Aws.config[:region]`
    #     * `ENV['AWS_REGION']`
    #     * `ENV['AMAZON_REGION']`
    #     * `ENV['AWS_DEFAULT_REGION']`
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #
    #   @option options [String] :access_key_id
    #
    #   @option options [Boolean] :active_endpoint_cache (false)
    #     When set to `true`, a thread polling for endpoints will be running in
    #     the background every 60 secs (default). Defaults to `false`.
    #
    #   @option options [Boolean] :client_side_monitoring (false)
    #     When `true`, client-side metrics will be collected for all API requests from
    #     this client.
    #
    #   @option options [String] :client_side_monitoring_client_id ("")
    #     Allows you to provide an identifier for this client which will be attached to
    #     all generated client side metrics. Defaults to an empty string.
    #
    #   @option options [Integer] :client_side_monitoring_port (31000)
    #     Required for publishing client metrics. The port that the client side monitoring
    #     agent is running on, where client metrics will be published via UDP.
    #
    #   @option options [Aws::ClientSideMonitoring::Publisher] :client_side_monitoring_publisher (Aws::ClientSideMonitoring::Publisher)
    #     Allows you to provide a custom client-side monitoring publisher class. By default,
    #     will use the Client Side Monitoring Agent Publisher.
    #
    #   @option options [Boolean] :convert_params (true)
    #     When `true`, an attempt is made to coerce request parameters into
    #     the required types.
    #
    #   @option options [Boolean] :disable_host_prefix_injection (false)
    #     Set to true to disable SDK automatically adding host prefix
    #     to default service endpoint when available.
    #
    #   @option options [String] :endpoint
    #     The client endpoint is normally constructed from the `:region`
    #     option. You should only configure an `:endpoint` when connecting
    #     to test endpoints. This should be avalid HTTP(S) URI.
    #
    #   @option options [Integer] :endpoint_cache_max_entries (1000)
    #     Used for the maximum size limit of the LRU cache storing endpoints data
    #     for endpoint discovery enabled operations. Defaults to 1000.
    #
    #   @option options [Integer] :endpoint_cache_max_threads (10)
    #     Used for the maximum threads in use for polling endpoints to be cached, defaults to 10.
    #
    #   @option options [Integer] :endpoint_cache_poll_interval (60)
    #     When :endpoint_discovery and :active_endpoint_cache is enabled,
    #     Use this option to config the time interval in seconds for making
    #     requests fetching endpoints information. Defaults to 60 sec.
    #
    #   @option options [Boolean] :endpoint_discovery (false)
    #     When set to `true`, endpoint discovery will be enabled for operations when available. Defaults to `false`.
    #
    #   @option options [Aws::Log::Formatter] :log_formatter (Aws::Log::Formatter.default)
    #     The log formatter.
    #
    #   @option options [Symbol] :log_level (:info)
    #     The log level to send messages to the `:logger` at.
    #
    #   @option options [Logger] :logger
    #     The Logger instance to send log messages to.  If this option
    #     is not set, logging will be disabled.
    #
    #   @option options [String] :profile ("default")
    #     Used when loading credentials from the shared credentials file
    #     at HOME/.aws/credentials.  When not specified, 'default' is used.
    #
    #   @option options [Float] :retry_base_delay (0.3)
    #     The base delay in seconds used by the default backoff function.
    #
    #   @option options [Symbol] :retry_jitter (:none)
    #     A delay randomiser function used by the default backoff function. Some predefined functions can be referenced by name - :none, :equal, :full, otherwise a Proc that takes and returns a number.
    #
    #     @see https://www.awsarchitectureblog.com/2015/03/backoff.html
    #
    #   @option options [Integer] :retry_limit (3)
    #     The maximum number of times to retry failed requests.  Only
    #     ~ 500 level server errors and certain ~ 400 level client errors
    #     are retried.  Generally, these are throttling errors, data
    #     checksum errors, networking errors, timeout errors and auth
    #     errors from expired credentials.
    #
    #   @option options [Integer] :retry_max_delay (0)
    #     The maximum number of seconds to delay between retries (0 for no limit) used by the default backoff function.
    #
    #   @option options [String] :secret_access_key
    #
    #   @option options [String] :session_token
    #
    #   @option options [Boolean] :simple_json (false)
    #     Disables request parameter conversion, validation, and formatting.
    #     Also disable response data type conversions. This option is useful
    #     when you want to ensure the highest level of performance by
    #     avoiding overhead of walking request parameters and response data
    #     structures.
    #
    #     When `:simple_json` is enabled, the request parameters hash must
    #     be formatted exactly as the DynamoDB API expects.
    #
    #   @option options [Boolean] :stub_responses (false)
    #     Causes the client to return stubbed responses. By default
    #     fake responses are generated and returned. You can specify
    #     the response data to return or errors to raise by calling
    #     {ClientStubs#stub_responses}. See {ClientStubs} for more information.
    #
    #     ** Please note ** When response stubbing is enabled, no HTTP
    #     requests are made, and retries are disabled.
    #
    #   @option options [Boolean] :validate_params (true)
    #     When `true`, request parameters are validated before
    #     sending the request.
    #
    #   @option options [URI::HTTP,String] :http_proxy A proxy to send
    #     requests through.  Formatted like 'http://proxy.com:123'.
    #
    #   @option options [Float] :http_open_timeout (15) The number of
    #     seconds to wait when opening a HTTP session before rasing a
    #     `Timeout::Error`.
    #
    #   @option options [Integer] :http_read_timeout (60) The default
    #     number of seconds to wait for response data.  This value can
    #     safely be set
    #     per-request on the session yeidled by {#session_for}.
    #
    #   @option options [Float] :http_idle_timeout (5) The number of
    #     seconds a connection is allowed to sit idble before it is
    #     considered stale.  Stale connections are closed and removed
    #     from the pool before making a request.
    #
    #   @option options [Float] :http_continue_timeout (1) The number of
    #     seconds to wait for a 100-continue response before sending the
    #     request body.  This option has no effect unless the request has
    #     "Expect" header set to "100-continue".  Defaults to `nil` which
    #     disables this behaviour.  This value can safely be set per
    #     request on the session yeidled by {#session_for}.
    #
    #   @option options [Boolean] :http_wire_trace (false) When `true`,
    #     HTTP debug output will be sent to the `:logger`.
    #
    #   @option options [Boolean] :ssl_verify_peer (true) When `true`,
    #     SSL peer certificates are verified when establishing a
    #     connection.
    #
    #   @option options [String] :ssl_ca_bundle Full path to the SSL
    #     certificate authority bundle file that should be used when
    #     verifying peer certificates.  If you do not pass
    #     `:ssl_ca_bundle` or `:ssl_ca_directory` the the system default
    #     will be used if available.
    #
    #   @option options [String] :ssl_ca_directory Full path of the
    #     directory that contains the unbundled SSL certificate
    #     authority files for verifying peer certificates.  If you do
    #     not pass `:ssl_ca_bundle` or `:ssl_ca_directory` the the
    #     system default will be used if available.
    #
    def initialize(*args)
      super
    end

    # @!group API Operations

    # Cancels the deletion of a customer master key (CMK). When this
    # operation is successful, the CMK is set to the `Disabled` state. To
    # enable a CMK, use EnableKey. You cannot perform this operation on a
    # CMK in a different AWS account.
    #
    # For more information about scheduling and canceling deletion of a CMK,
    # see [Deleting Customer Master Keys][1] in the *AWS Key Management
    # Service Developer Guide*.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The unique identifier for the customer master key (CMK) for which to
    #   cancel deletion.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Types::CancelKeyDeletionResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CancelKeyDeletionResponse#key_id #key_id} => String
    #
    #
    # @example Example: To cancel deletion of a customer master key (CMK)
    #
    #   # The following example cancels deletion of the specified CMK.
    #
    #   resp = client.cancel_key_deletion({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose deletion you are canceling. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK whose deletion you canceled.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.cancel_key_deletion({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CancelKeyDeletion AWS API Documentation
    #
    # @overload cancel_key_deletion(params = {})
    # @param [Hash] params ({})
    def cancel_key_deletion(params = {}, options = {})
      req = build_request(:cancel_key_deletion, params)
      req.send_request(options)
    end

    # Connects or reconnects a [custom key store][1] to its associated AWS
    # CloudHSM cluster.
    #
    # The custom key store must be connected before you can create customer
    # master keys (CMKs) in the key store or use the CMKs it contains. You
    # can disconnect and reconnect a custom key store at any time.
    #
    # To connect a custom key store, its associated AWS CloudHSM cluster
    # must have at least one active HSM. To get the number of active HSMs in
    # a cluster, use the [DescribeClusters][2] operation. To add HSMs to the
    # cluster, use the [CreateHsm][3] operation.
    #
    # The connection process can take an extended amount of time to
    # complete; up to 20 minutes. This operation starts the connection
    # process, but it does not wait for it to complete. When it succeeds,
    # this operation quickly returns an HTTP 200 response and a JSON object
    # with no properties. However, this response does not indicate that the
    # custom key store is connected. To get the connection state of the
    # custom key store, use the DescribeCustomKeyStores operation.
    #
    # During the connection process, AWS KMS finds the AWS CloudHSM cluster
    # that is associated with the custom key store, creates the connection
    # infrastructure, connects to the cluster, logs into the AWS CloudHSM
    # client as the [ `kmsuser` crypto user][4] (CU), and rotates its
    # password.
    #
    # The `ConnectCustomKeyStore` operation might fail for various reasons.
    # To find the reason, use the DescribeCustomKeyStores operation and see
    # the `ConnectionErrorCode` in the response. For help interpreting the
    # `ConnectionErrorCode`, see CustomKeyStoresListEntry.
    #
    # To fix the failure, use the DisconnectCustomKeyStore operation to
    # disconnect the custom key store, correct the error, use the
    # UpdateCustomKeyStore operation if necessary, and then use
    # `ConnectCustomKeyStore` again.
    #
    # If you are having trouble connecting or disconnecting a custom key
    # store, see [Troubleshooting a Custom Key Store][5] in the *AWS Key
    # Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    # [3]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the key store ID of the custom key store that you want to
    #   connect. To find the ID of a custom key store, use the
    #   DescribeCustomKeyStores operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.connect_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ConnectCustomKeyStore AWS API Documentation
    #
    # @overload connect_custom_key_store(params = {})
    # @param [Hash] params ({})
    def connect_custom_key_store(params = {}, options = {})
      req = build_request(:connect_custom_key_store, params)
      req.send_request(options)
    end

    # Creates a display name for a customer managed customer master key
    # (CMK). You can use an alias to identify a CMK in selected operations,
    # such as Encrypt and GenerateDataKey.
    #
    # Each CMK can have multiple aliases, but each alias points to only one
    # CMK. The alias name must be unique in the AWS account and region. To
    # simplify code that runs in multiple regions, use the same alias name,
    # but point it to a different CMK in each region.
    #
    # Because an alias is not a property of a CMK, you can delete and change
    # the aliases of a CMK without affecting the CMK. Also, aliases do not
    # appear in the response from the DescribeKey operation. To get the
    # aliases of all CMKs, use the ListAliases operation.
    #
    # The alias name must begin with `alias/` followed by a name, such as
    # `alias/ExampleAlias`. It can contain only alphanumeric characters,
    # forward slashes (/), underscores (\_), and dashes (-). The alias name
    # cannot begin with `alias/aws/`. The `alias/aws/` prefix is reserved
    # for [AWS managed CMKs][1].
    #
    # The alias and the CMK it is mapped to must be in the same AWS account
    # and the same region. You cannot perform this operation on an alias in
    # a different AWS account.
    #
    # To map an existing alias to a different CMK, call UpdateAlias.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :alias_name
    #   Specifies the alias name. This value must begin with `alias/` followed
    #   by a name, such as `alias/ExampleAlias`. The alias name cannot begin
    #   with `alias/aws/`. The `alias/aws/` prefix is reserved for AWS managed
    #   CMKs.
    #
    # @option params [required, String] :target_key_id
    #   Identifies the CMK to which the alias refers. Specify the key ID or
    #   the Amazon Resource Name (ARN) of the CMK. You cannot specify another
    #   alias. For help finding the key ID and ARN, see [Finding the Key ID
    #   and ARN][1] in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/viewing-keys.html#find-cmk-id-arn
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To create an alias
    #
    #   # The following example creates an alias for the specified customer master key (CMK).
    #
    #   resp = client.create_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to create. Aliases must begin with 'alias/'. Do not use aliases that begin with 'alias/aws' because they are reserved for use by AWS.
    #     target_key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose alias you are creating. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_alias({
    #     alias_name: "AliasNameType", # required
    #     target_key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateAlias AWS API Documentation
    #
    # @overload create_alias(params = {})
    # @param [Hash] params ({})
    def create_alias(params = {}, options = {})
      req = build_request(:create_alias, params)
      req.send_request(options)
    end

    # Creates a [custom key store][1] that is associated with an [AWS
    # CloudHSM cluster][2] that you own and manage.
    #
    # This operation is part of the [Custom Key Store feature][1] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    # Before you create the custom key store, you must assemble the required
    # elements, including an AWS CloudHSM cluster that fulfills the
    # requirements for a custom key store. For details about the required
    # elements, see [Assemble the Prerequisites][3] in the *AWS Key
    # Management Service Developer Guide*.
    #
    # When the operation completes successfully, it returns the ID of the
    # new custom key store. Before you can use your new custom key store,
    # you need to use the ConnectCustomKeyStore operation to connect the new
    # key store to its AWS CloudHSM cluster. Even if you are not going to
    # use your custom key store immediately, you might want to connect it to
    # verify that all settings are correct and then disconnect it until you
    # are ready to use it.
    #
    # For help with failures, see [Troubleshooting a Custom Key Store][4] in
    # the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    #
    # @option params [required, String] :custom_key_store_name
    #   Specifies a friendly name for the custom key store. The name must be
    #   unique in your AWS account.
    #
    # @option params [required, String] :cloud_hsm_cluster_id
    #   Identifies the AWS CloudHSM cluster for the custom key store. Enter
    #   the cluster ID of any active AWS CloudHSM cluster that is not already
    #   associated with a custom key store. To find the cluster ID, use the
    #   [DescribeClusters][1] operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #
    # @option params [required, String] :trust_anchor_certificate
    #   Enter the content of the trust anchor certificate for the cluster.
    #   This is the content of the `customerCA.crt` file that you created when
    #   you [initialized the cluster][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/initialize-cluster.html
    #
    # @option params [required, String] :key_store_password
    #   Enter the password of the [ `kmsuser` crypto user (CU) account][1] in
    #   the specified AWS CloudHSM cluster. AWS KMS logs into the cluster as
    #   this user to manage key material on your behalf.
    #
    #   This parameter tells AWS KMS the `kmsuser` account password; it does
    #   not change the password in the AWS CloudHSM cluster.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser
    #
    # @return [Types::CreateCustomKeyStoreResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateCustomKeyStoreResponse#custom_key_store_id #custom_key_store_id} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_custom_key_store({
    #     custom_key_store_name: "CustomKeyStoreNameType", # required
    #     cloud_hsm_cluster_id: "CloudHsmClusterIdType", # required
    #     trust_anchor_certificate: "TrustAnchorCertificateType", # required
    #     key_store_password: "KeyStorePasswordType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.custom_key_store_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateCustomKeyStore AWS API Documentation
    #
    # @overload create_custom_key_store(params = {})
    # @param [Hash] params ({})
    def create_custom_key_store(params = {}, options = {})
      req = build_request(:create_custom_key_store, params)
      req.send_request(options)
    end

    # Adds a grant to a customer master key (CMK). The grant allows the
    # grantee principal to use the CMK when the conditions specified in the
    # grant are met. When setting permissions, grants are an alternative to
    # key policies.
    #
    # To create a grant that allows a cryptographic operation only when the
    # encryption context in the operation request matches or includes a
    # specified encryption context, use the `Constraints` parameter. For
    # details, see GrantConstraints.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN in the value of the `KeyId` parameter. For more
    # information about grants, see [Grants][1] in the <i> <i>AWS Key
    # Management Service Developer Guide</i> </i>.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The unique identifier for the customer master key (CMK) that the grant
    #   applies to.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :grantee_principal
    #   The principal that is given permission to perform the operations that
    #   the grant permits.
    #
    #   To specify the principal, use the [Amazon Resource Name (ARN)][1] of
    #   an AWS principal. Valid AWS principals include AWS accounts (root),
    #   IAM users, IAM roles, federated users, and assumed role users. For
    #   examples of the ARN syntax to use for specifying a principal, see [AWS
    #   Identity and Access Management (IAM)][2] in the Example ARNs section
    #   of the *AWS General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #
    # @option params [String] :retiring_principal
    #   The principal that is given permission to retire the grant by using
    #   RetireGrant operation.
    #
    #   To specify the principal, use the [Amazon Resource Name (ARN)][1] of
    #   an AWS principal. Valid AWS principals include AWS accounts (root),
    #   IAM users, federated users, and assumed role users. For examples of
    #   the ARN syntax to use for specifying a principal, see [AWS Identity
    #   and Access Management (IAM)][2] in the Example ARNs section of the
    #   *AWS General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #
    # @option params [required, Array<String>] :operations
    #   A list of operations that the grant permits.
    #
    # @option params [Types::GrantConstraints] :constraints
    #   Allows a cryptographic operation only when the encryption context
    #   matches or includes the encryption context specified in this
    #   structure. For more information about encryption context, see
    #   [Encryption Context][1] in the <i> <i>AWS Key Management Service
    #   Developer Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @option params [String] :name
    #   A friendly name for identifying the grant. Use this value to prevent
    #   the unintended creation of duplicate grants when retrying this
    #   request.
    #
    #   When this value is absent, all `CreateGrant` requests result in a new
    #   grant with a unique `GrantId` even if all the supplied parameters are
    #   identical. This can result in unintended duplicates when you retry the
    #   `CreateGrant` request.
    #
    #   When this value is present, you can retry a `CreateGrant` request with
    #   identical parameters; if the grant already exists, the original
    #   `GrantId` is returned without creating a new grant. Note that the
    #   returned grant token is unique with every `CreateGrant` request, even
    #   when a duplicate `GrantId` is returned. All grant tokens obtained in
    #   this way can be used interchangeably.
    #
    # @return [Types::CreateGrantResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateGrantResponse#grant_token #grant_token} => String
    #   * {Types::CreateGrantResponse#grant_id #grant_id} => String
    #
    #
    # @example Example: To create a grant
    #
    #   # The following example creates a grant that allows the specified IAM role to encrypt data with the specified customer
    #   # master key (CMK).
    #
    #   resp = client.create_grant({
    #     grantee_principal: "arn:aws:iam::111122223333:role/ExampleRole", # The identity that is given permission to perform the operations specified in the grant.
    #     key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to which the grant applies. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     operations: [
    #       "Encrypt", 
    #       "Decrypt", 
    #     ], # A list of operations that the grant allows.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The unique identifier of the grant.
    #     grant_token: "AQpAM2RhZTk1MGMyNTk2ZmZmMzEyYWVhOWViN2I1MWM4Mzc0MWFiYjc0ZDE1ODkyNGFlNTIzODZhMzgyZjBlNGY3NiKIAgEBAgB4Pa6VDCWW__MSrqnre1HIN0Grt00ViSSuUjhqOC8OT3YAAADfMIHcBgkqhkiG9w0BBwaggc4wgcsCAQAwgcUGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMmqLyBTAegIn9XlK5AgEQgIGXZQjkBcl1dykDdqZBUQ6L1OfUivQy7JVYO2-ZJP7m6f1g8GzV47HX5phdtONAP7K_HQIflcgpkoCqd_fUnE114mSmiagWkbQ5sqAVV3ov-VeqgrvMe5ZFEWLMSluvBAqdjHEdMIkHMlhlj4ENZbzBfo9Wxk8b8SnwP4kc4gGivedzFXo-dwN8fxjjq_ZZ9JFOj2ijIbj5FyogDCN0drOfi8RORSEuCEmPvjFRMFAwcmwFkN2NPp89amA", # The grant token.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_grant({
    #     key_id: "KeyIdType", # required
    #     grantee_principal: "PrincipalIdType", # required
    #     retiring_principal: "PrincipalIdType",
    #     operations: ["Decrypt"], # required, accepts Decrypt, Encrypt, GenerateDataKey, GenerateDataKeyWithoutPlaintext, ReEncryptFrom, ReEncryptTo, CreateGrant, RetireGrant, DescribeKey
    #     constraints: {
    #       encryption_context_subset: {
    #         "EncryptionContextKey" => "EncryptionContextValue",
    #       },
    #       encryption_context_equals: {
    #         "EncryptionContextKey" => "EncryptionContextValue",
    #       },
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #     name: "GrantNameType",
    #   })
    #
    # @example Response structure
    #
    #   resp.grant_token #=> String
    #   resp.grant_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateGrant AWS API Documentation
    #
    # @overload create_grant(params = {})
    # @param [Hash] params ({})
    def create_grant(params = {}, options = {})
      req = build_request(:create_grant, params)
      req.send_request(options)
    end

    # Creates a customer managed [customer master key][1] (CMK) in your AWS
    # account.
    #
    # You can use a CMK to encrypt small amounts of data (up to 4096 bytes)
    # directly. But CMKs are more commonly used to encrypt the [data
    # keys][2] that are used to encrypt data.
    #
    # To create a CMK for imported key material, use the `Origin` parameter
    # with a value of `EXTERNAL`.
    #
    # To create a CMK in a [custom key store][3], use the `CustomKeyStoreId`
    # parameter to specify the custom key store. You must also use the
    # `Origin` parameter with a value of `AWS_CLOUDHSM`. The AWS CloudHSM
    # cluster that is associated with the custom key store must have at
    # least two active HSMs in different Availability Zones in the AWS
    # Region.
    #
    # You cannot use this operation to create a CMK in a different AWS
    # account.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [String] :policy
    #   The key policy to attach to the CMK.
    #
    #   If you provide a key policy, it must meet the following criteria:
    #
    #   * If you don't set `BypassPolicyLockoutSafetyCheck` to true, the key
    #     policy must allow the principal that is making the `CreateKey`
    #     request to make a subsequent PutKeyPolicy request on the CMK. This
    #     reduces the risk that the CMK becomes unmanageable. For more
    #     information, refer to the scenario in the [Default Key Policy][1]
    #     section of the <i> <i>AWS Key Management Service Developer Guide</i>
    #     </i>.
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to AWS KMS. When you create a new AWS principal (for
    #     example, an IAM user or role), you might need to enforce a delay
    #     before including the new principal in a key policy because the new
    #     principal might not be immediately visible to AWS KMS. For more
    #     information, see [Changes that I make are not always immediately
    #     visible][2] in the *AWS Identity and Access Management User Guide*.
    #
    #   If you do not provide a key policy, AWS KMS attaches a default key
    #   policy to the CMK. For more information, see [Default Key Policy][3]
    #   in the *AWS Key Management Service Developer Guide*.
    #
    #   The key policy size limit is 32 kilobytes (32768 bytes).
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default
    #
    # @option params [String] :description
    #   A description of the CMK.
    #
    #   Use a description that helps you decide whether the CMK is appropriate
    #   for a task.
    #
    # @option params [String] :key_usage
    #   The cryptographic operations for which you can use the CMK. The only
    #   valid value is `ENCRYPT_DECRYPT`, which means you can use the CMK to
    #   encrypt and decrypt data.
    #
    # @option params [String] :origin
    #   The source of the key material for the CMK. You cannot change the
    #   origin after you create the CMK.
    #
    #   The default is `AWS_KMS`, which means AWS KMS creates the key material
    #   in its own key store.
    #
    #   When the parameter value is `EXTERNAL`, AWS KMS creates a CMK without
    #   key material so that you can import key material from your existing
    #   key management infrastructure. For more information about importing
    #   key material into AWS KMS, see [Importing Key Material][1] in the *AWS
    #   Key Management Service Developer Guide*.
    #
    #   When the parameter value is `AWS_CLOUDHSM`, AWS KMS creates the CMK in
    #   an AWS KMS [custom key store][2] and creates its key material in the
    #   associated AWS CloudHSM cluster. You must also use the
    #   `CustomKeyStoreId` parameter to identify the custom key store.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [String] :custom_key_store_id
    #   Creates the CMK in the specified [custom key store][1] and the key
    #   material in its associated AWS CloudHSM cluster. To create a CMK in a
    #   custom key store, you must also specify the `Origin` parameter with a
    #   value of `AWS_CLOUDHSM`. The AWS CloudHSM cluster that is associated
    #   with the custom key store must have at least two active HSMs, each in
    #   a different Availability Zone in the Region.
    #
    #   To find the ID of a custom key store, use the DescribeCustomKeyStores
    #   operation.
    #
    #   The response includes the custom key store ID and the ID of the AWS
    #   CloudHSM cluster.
    #
    #   This operation is part of the [Custom Key Store feature][1] feature in
    #   AWS KMS, which combines the convenience and extensive integration of
    #   AWS KMS with the isolation and control of a single-tenant key store.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [Boolean] :bypass_policy_lockout_safety_check
    #   A flag to indicate whether to bypass the key policy lockout safety
    #   check.
    #
    #   Setting this value to true increases the risk that the CMK becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, refer to the scenario in the [Default Key
    #   Policy][1] section in the <i> <i>AWS Key Management Service Developer
    #   Guide</i> </i>.
    #
    #   Use this parameter only when you include a policy in the request and
    #   you intend to prevent the principal that is making the request from
    #   making a subsequent PutKeyPolicy request on the CMK.
    #
    #   The default value is false.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #
    # @option params [Array<Types::Tag>] :tags
    #   One or more tags. Each tag consists of a tag key and a tag value. Tag
    #   keys and tag values are both required, but tag values can be empty
    #   (null) strings.
    #
    #   Use this parameter to tag the CMK when it is created. Alternately, you
    #   can omit this parameter and instead tag the CMK after it is created
    #   using TagResource.
    #
    # @return [Types::CreateKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateKeyResponse#key_metadata #key_metadata} => Types::KeyMetadata
    #
    #
    # @example Example: To create a customer master key (CMK)
    #
    #   # The following example creates a CMK.
    #
    #   resp = client.create_key({
    #     tags: [
    #       {
    #         tag_key: "CreatedBy", 
    #         tag_value: "ExampleUser", 
    #       }, 
    #     ], # One or more tags. Each tag consists of a tag key and a tag value.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2017-07-05T14:04:55-07:00"), 
    #       description: "", 
    #       enabled: true, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       origin: "AWS_KMS", 
    #     }, # An object that contains information about the CMK created by this operation.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_key({
    #     policy: "PolicyType",
    #     description: "DescriptionType",
    #     key_usage: "ENCRYPT_DECRYPT", # accepts ENCRYPT_DECRYPT
    #     origin: "AWS_KMS", # accepts AWS_KMS, EXTERNAL, AWS_CLOUDHSM
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #     bypass_policy_lockout_safety_check: false,
    #     tags: [
    #       {
    #         tag_key: "TagKeyType", # required
    #         tag_value: "TagValueType", # required
    #       },
    #     ],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_metadata.aws_account_id #=> String
    #   resp.key_metadata.key_id #=> String
    #   resp.key_metadata.arn #=> String
    #   resp.key_metadata.creation_date #=> Time
    #   resp.key_metadata.enabled #=> Boolean
    #   resp.key_metadata.description #=> String
    #   resp.key_metadata.key_usage #=> String, one of "ENCRYPT_DECRYPT"
    #   resp.key_metadata.key_state #=> String, one of "Enabled", "Disabled", "PendingDeletion", "PendingImport", "Unavailable"
    #   resp.key_metadata.deletion_date #=> Time
    #   resp.key_metadata.valid_to #=> Time
    #   resp.key_metadata.origin #=> String, one of "AWS_KMS", "EXTERNAL", "AWS_CLOUDHSM"
    #   resp.key_metadata.custom_key_store_id #=> String
    #   resp.key_metadata.cloud_hsm_cluster_id #=> String
    #   resp.key_metadata.expiration_model #=> String, one of "KEY_MATERIAL_EXPIRES", "KEY_MATERIAL_DOES_NOT_EXPIRE"
    #   resp.key_metadata.key_manager #=> String, one of "AWS", "CUSTOMER"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateKey AWS API Documentation
    #
    # @overload create_key(params = {})
    # @param [Hash] params ({})
    def create_key(params = {}, options = {})
      req = build_request(:create_key, params)
      req.send_request(options)
    end

    # Decrypts ciphertext. Ciphertext is plaintext that has been previously
    # encrypted by using any of the following operations:
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyWithoutPlaintext
    #
    # * Encrypt
    #
    # Whenever possible, use key policies to give users permission to call
    # the Decrypt operation on the CMK, instead of IAM policies. Otherwise,
    # you might create an IAM user policy that gives the user Decrypt
    # permission on all CMKs. This user could decrypt ciphertext that was
    # encrypted by CMKs in other accounts if the key policy for the
    # cross-account CMK permits it. If you must use an IAM policy for
    # `Decrypt` permissions, limit the user to particular CMKs or particular
    # trusted accounts.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][1]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String, IO] :ciphertext_blob
    #   Ciphertext to be decrypted. The blob includes metadata.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   The encryption context. If this was specified in the Encrypt function,
    #   it must be specified here or the decryption operation will fail. For
    #   more information, see [Encryption Context][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::DecryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DecryptResponse#key_id #key_id} => String
    #   * {Types::DecryptResponse#plaintext #plaintext} => String
    #
    #
    # @example Example: To decrypt data
    #
    #   # The following example decrypts data that was encrypted with a customer master key (CMK) in AWS KMS.
    #
    #   resp = client.decrypt({
    #     ciphertext_blob: "<binary data>", # The encrypted data (ciphertext).
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The Amazon Resource Name (ARN) of the CMK that was used to decrypt the data.
    #     plaintext: "<binary data>", # The decrypted (plaintext) data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.decrypt({
    #     ciphertext_blob: "data", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.plaintext #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Decrypt AWS API Documentation
    #
    # @overload decrypt(params = {})
    # @param [Hash] params ({})
    def decrypt(params = {}, options = {})
      req = build_request(:decrypt, params)
      req.send_request(options)
    end

    # Deletes the specified alias. You cannot perform this operation on an
    # alias in a different AWS account.
    #
    # Because an alias is not a property of a CMK, you can delete and change
    # the aliases of a CMK without affecting the CMK. Also, aliases do not
    # appear in the response from the DescribeKey operation. To get the
    # aliases of all CMKs, use the ListAliases operation.
    #
    # Each CMK can have multiple aliases. To change the alias of a CMK, use
    # DeleteAlias to delete the current alias and CreateAlias to create a
    # new alias. To associate an existing alias with a different customer
    # master key (CMK), call UpdateAlias.
    #
    # @option params [required, String] :alias_name
    #   The alias to be deleted. The alias name must begin with `alias/`
    #   followed by the alias name, such as `alias/ExampleAlias`.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete an alias
    #
    #   # The following example deletes the specified alias.
    #
    #   resp = client.delete_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to delete.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_alias({
    #     alias_name: "AliasNameType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteAlias AWS API Documentation
    #
    # @overload delete_alias(params = {})
    # @param [Hash] params ({})
    def delete_alias(params = {}, options = {})
      req = build_request(:delete_alias, params)
      req.send_request(options)
    end

    # Deletes a [custom key store][1]. This operation does not delete the
    # AWS CloudHSM cluster that is associated with the custom key store, or
    # affect any users or keys in the cluster.
    #
    # The custom key store that you delete cannot contain any AWS KMS
    # [customer master keys (CMKs)][2]. Before deleting the key store,
    # verify that you will never need to use any of the CMKs in the key
    # store for any cryptographic operations. Then, use ScheduleKeyDeletion
    # to delete the AWS KMS customer master keys (CMKs) from the key store.
    # When the scheduled waiting period expires, the `ScheduleKeyDeletion`
    # operation deletes the CMKs. Then it makes a best effort to delete the
    # key material from the associated cluster. However, you might need to
    # manually [delete the orphaned key material][3] from the cluster and
    # its backups.
    #
    # After all CMKs are deleted from AWS KMS, use DisconnectCustomKeyStore
    # to disconnect the key store from AWS KMS. Then, you can delete the
    # custom key store.
    #
    # Instead of deleting the custom key store, consider using
    # DisconnectCustomKeyStore to disconnect it from AWS KMS. While the key
    # store is disconnected, you cannot create or use the CMKs in the key
    # store. But, you do not need to delete CMKs and you can reconnect a
    # disconnected custom key store at any time.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # This operation is part of the [Custom Key Store feature][1] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the ID of the custom key store you want to delete. To find the
    #   ID of a custom key store, use the DescribeCustomKeyStores operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteCustomKeyStore AWS API Documentation
    #
    # @overload delete_custom_key_store(params = {})
    # @param [Hash] params ({})
    def delete_custom_key_store(params = {}, options = {})
      req = build_request(:delete_custom_key_store, params)
      req.send_request(options)
    end

    # Deletes key material that you previously imported. This operation
    # makes the specified customer master key (CMK) unusable. For more
    # information about importing key material into AWS KMS, see [Importing
    # Key Material][1] in the *AWS Key Management Service Developer Guide*.
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # When the specified CMK is in the `PendingDeletion` state, this
    # operation does not change the CMK's state. Otherwise, it changes the
    # CMK's state to `PendingImport`.
    #
    # After you delete key material, you can use ImportKeyMaterial to
    # reimport the same key material into the CMK.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   Identifies the CMK from which you are deleting imported key material.
    #   The `Origin` of the CMK must be `EXTERNAL`.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete imported key material
    #
    #   # The following example deletes the imported key material from the specified customer master key (CMK).
    #
    #   resp = client.delete_imported_key_material({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose imported key material you are deleting. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_imported_key_material({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteImportedKeyMaterial AWS API Documentation
    #
    # @overload delete_imported_key_material(params = {})
    # @param [Hash] params ({})
    def delete_imported_key_material(params = {}, options = {})
      req = build_request(:delete_imported_key_material, params)
      req.send_request(options)
    end

    # Gets information about [custom key stores][1] in the account and
    # region.
    #
    # This operation is part of the [Custom Key Store feature][1] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    # By default, this operation returns information about all custom key
    # stores in the account and region. To get only information about a
    # particular custom key store, use either the `CustomKeyStoreName` or
    # `CustomKeyStoreId` parameter (but not both).
    #
    # To determine whether the custom key store is connected to its AWS
    # CloudHSM cluster, use the `ConnectionState` element in the response.
    # If an attempt to connect the custom key store failed, the
    # `ConnectionState` value is `FAILED` and the `ConnectionErrorCode`
    # element in the response indicates the cause of the failure. For help
    # interpreting the `ConnectionErrorCode`, see CustomKeyStoresListEntry.
    #
    # Custom key stores have a `DISCONNECTED` connection state if the key
    # store has never been connected or you use the DisconnectCustomKeyStore
    # operation to disconnect it. If your custom key store state is
    # `CONNECTED` but you are having trouble using it, make sure that its
    # associated AWS CloudHSM cluster is active and contains the minimum
    # number of HSMs required for the operation, if any.
    #
    # For help repairing your custom key store, see the [Troubleshooting
    # Custom Key Stores][2] topic in the *AWS Key Management Service
    # Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    #
    # @option params [String] :custom_key_store_id
    #   Gets only information about the specified custom key store. Enter the
    #   key store ID.
    #
    #   By default, this operation gets information about all custom key
    #   stores in the account and region. To limit the output to a particular
    #   custom key store, you can use either the `CustomKeyStoreId` or
    #   `CustomKeyStoreName` parameter, but not both.
    #
    # @option params [String] :custom_key_store_name
    #   Gets only information about the specified custom key store. Enter the
    #   friendly name of the custom key store.
    #
    #   By default, this operation gets information about all custom key
    #   stores in the account and region. To limit the output to a particular
    #   custom key store, you can use either the `CustomKeyStoreId` or
    #   `CustomKeyStoreName` parameter, but not both.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::DescribeCustomKeyStoresResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DescribeCustomKeyStoresResponse#custom_key_stores #custom_key_stores} => Array&lt;Types::CustomKeyStoresListEntry&gt;
    #   * {Types::DescribeCustomKeyStoresResponse#next_marker #next_marker} => String
    #   * {Types::DescribeCustomKeyStoresResponse#truncated #truncated} => Boolean
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.describe_custom_key_stores({
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #     custom_key_store_name: "CustomKeyStoreNameType",
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.custom_key_stores #=> Array
    #   resp.custom_key_stores[0].custom_key_store_id #=> String
    #   resp.custom_key_stores[0].custom_key_store_name #=> String
    #   resp.custom_key_stores[0].cloud_hsm_cluster_id #=> String
    #   resp.custom_key_stores[0].trust_anchor_certificate #=> String
    #   resp.custom_key_stores[0].connection_state #=> String, one of "CONNECTED", "CONNECTING", "FAILED", "DISCONNECTED", "DISCONNECTING"
    #   resp.custom_key_stores[0].connection_error_code #=> String, one of "INVALID_CREDENTIALS", "CLUSTER_NOT_FOUND", "NETWORK_ERRORS", "INTERNAL_ERROR", "INSUFFICIENT_CLOUDHSM_HSMS", "USER_LOCKED_OUT"
    #   resp.custom_key_stores[0].creation_date #=> Time
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeCustomKeyStores AWS API Documentation
    #
    # @overload describe_custom_key_stores(params = {})
    # @param [Hash] params ({})
    def describe_custom_key_stores(params = {}, options = {})
      req = build_request(:describe_custom_key_stores, params)
      req.send_request(options)
    end

    # Provides detailed information about the specified customer master key
    # (CMK).
    #
    # You can use `DescribeKey` on a predefined AWS alias, that is, an AWS
    # alias with no key ID. When you do, AWS KMS associates the alias with
    # an [AWS managed CMK][1] and returns its `KeyId` and `Arn` in the
    # response.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN or alias ARN in the value of the KeyId parameter.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    #
    # @option params [required, String] :key_id
    #   Describes the specified customer master key (CMK).
    #
    #   If you specify a predefined AWS alias (an AWS alias with no key ID),
    #   KMS associates the alias with an [AWS managed CMK][1] and returns its
    #   `KeyId` and `Arn` in the response.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::DescribeKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DescribeKeyResponse#key_metadata #key_metadata} => Types::KeyMetadata
    #
    #
    # @example Example: To obtain information about a customer master key (CMK)
    #
    #   # The following example returns information (metadata) about the specified CMK.
    #
    #   resp = client.describe_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK that you want information about. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2017-07-05T14:04:55-07:00"), 
    #       description: "", 
    #       enabled: true, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       origin: "AWS_KMS", 
    #     }, # An object that contains information about the specified CMK.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.describe_key({
    #     key_id: "KeyIdType", # required
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_metadata.aws_account_id #=> String
    #   resp.key_metadata.key_id #=> String
    #   resp.key_metadata.arn #=> String
    #   resp.key_metadata.creation_date #=> Time
    #   resp.key_metadata.enabled #=> Boolean
    #   resp.key_metadata.description #=> String
    #   resp.key_metadata.key_usage #=> String, one of "ENCRYPT_DECRYPT"
    #   resp.key_metadata.key_state #=> String, one of "Enabled", "Disabled", "PendingDeletion", "PendingImport", "Unavailable"
    #   resp.key_metadata.deletion_date #=> Time
    #   resp.key_metadata.valid_to #=> Time
    #   resp.key_metadata.origin #=> String, one of "AWS_KMS", "EXTERNAL", "AWS_CLOUDHSM"
    #   resp.key_metadata.custom_key_store_id #=> String
    #   resp.key_metadata.cloud_hsm_cluster_id #=> String
    #   resp.key_metadata.expiration_model #=> String, one of "KEY_MATERIAL_EXPIRES", "KEY_MATERIAL_DOES_NOT_EXPIRE"
    #   resp.key_metadata.key_manager #=> String, one of "AWS", "CUSTOMER"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeKey AWS API Documentation
    #
    # @overload describe_key(params = {})
    # @param [Hash] params ({})
    def describe_key(params = {}, options = {})
      req = build_request(:describe_key, params)
      req.send_request(options)
    end

    # Sets the state of a customer master key (CMK) to disabled, thereby
    # preventing its use for cryptographic operations. You cannot perform
    # this operation on a CMK in a different AWS account.
    #
    # For more information about how key state affects the use of a CMK, see
    # [How Key State Affects the Use of a Customer Master Key][1] in the <i>
    # <i>AWS Key Management Service Developer Guide</i> </i>.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][1]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To disable a customer master key (CMK)
    #
    #   # The following example disables the specified CMK.
    #
    #   resp = client.disable_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to disable. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disable_key({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisableKey AWS API Documentation
    #
    # @overload disable_key(params = {})
    # @param [Hash] params ({})
    def disable_key(params = {}, options = {})
      req = build_request(:disable_key, params)
      req.send_request(options)
    end

    # Disables [automatic rotation of the key material][1] for the specified
    # customer master key (CMK). You cannot perform this operation on a CMK
    # in a different AWS account.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To disable automatic rotation of key material
    #
    #   # The following example disables automatic annual rotation of the key material for the specified CMK.
    #
    #   resp = client.disable_key_rotation({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key material will no longer be rotated. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disable_key_rotation({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisableKeyRotation AWS API Documentation
    #
    # @overload disable_key_rotation(params = {})
    # @param [Hash] params ({})
    def disable_key_rotation(params = {}, options = {})
      req = build_request(:disable_key_rotation, params)
      req.send_request(options)
    end

    # Disconnects the [custom key store][1] from its associated AWS CloudHSM
    # cluster. While a custom key store is disconnected, you can manage the
    # custom key store and its customer master keys (CMKs), but you cannot
    # create or use CMKs in the custom key store. You can reconnect the
    # custom key store at any time.
    #
    # <note markdown="1"> While a custom key store is disconnected, all attempts to create
    # customer master keys (CMKs) in the custom key store or to use existing
    # CMKs in cryptographic operations will fail. This action can prevent
    # users from storing and accessing sensitive data.
    #
    #  </note>
    #
    #
    #
    # To find the connection state of a custom key store, use the
    # DescribeCustomKeyStores operation. To reconnect a custom key store,
    # use the ConnectCustomKeyStore operation.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # This operation is part of the [Custom Key Store feature][1] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the ID of the custom key store you want to disconnect. To find
    #   the ID of a custom key store, use the DescribeCustomKeyStores
    #   operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disconnect_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisconnectCustomKeyStore AWS API Documentation
    #
    # @overload disconnect_custom_key_store(params = {})
    # @param [Hash] params ({})
    def disconnect_custom_key_store(params = {}, options = {})
      req = build_request(:disconnect_custom_key_store, params)
      req.send_request(options)
    end

    # Sets the key state of a customer master key (CMK) to enabled. This
    # allows you to use the CMK for cryptographic operations. You cannot
    # perform this operation on a CMK in a different AWS account.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][1]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To enable a customer master key (CMK)
    #
    #   # The following example enables the specified CMK.
    #
    #   resp = client.enable_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to enable. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.enable_key({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EnableKey AWS API Documentation
    #
    # @overload enable_key(params = {})
    # @param [Hash] params ({})
    def enable_key(params = {}, options = {})
      req = build_request(:enable_key, params)
      req.send_request(options)
    end

    # Enables [automatic rotation of the key material][1] for the specified
    # customer master key (CMK). You cannot perform this operation on a CMK
    # in a different AWS account.
    #
    # You cannot enable automatic rotation of CMKs with imported key
    # material or CMKs in a [custom key store][2].
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][3]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To enable automatic rotation of key material
    #
    #   # The following example enables automatic annual rotation of the key material for the specified CMK.
    #
    #   resp = client.enable_key_rotation({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key material will be rotated annually. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.enable_key_rotation({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EnableKeyRotation AWS API Documentation
    #
    # @overload enable_key_rotation(params = {})
    # @param [Hash] params ({})
    def enable_key_rotation(params = {}, options = {})
      req = build_request(:enable_key_rotation, params)
      req.send_request(options)
    end

    # Encrypts plaintext into ciphertext by using a customer master key
    # (CMK). The `Encrypt` operation has two primary use cases:
    #
    # * You can encrypt up to 4 kilobytes (4096 bytes) of arbitrary data
    #   such as an RSA key, a database password, or other sensitive
    #   information.
    #
    # * You can use the `Encrypt` operation to move encrypted data from one
    #   AWS region to another. In the first region, generate a data key and
    #   use the plaintext key to encrypt the data. Then, in the new region,
    #   call the `Encrypt` method on same plaintext data key. Now, you can
    #   safely move the encrypted data and encrypted data key to the new
    #   region, and decrypt in the new region when necessary.
    #
    # You don't need use this operation to encrypt a data key within a
    # region. The GenerateDataKey and GenerateDataKeyWithoutPlaintext
    # operations return an encrypted data key.
    #
    # Also, you don't need to use this operation to encrypt data in your
    # application. You can use the plaintext and encrypted data keys that
    # the `GenerateDataKey` operation returns.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][1]
    # in the *AWS Key Management Service Developer Guide*.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN or alias ARN in the value of the KeyId parameter.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String, IO] :plaintext
    #   Data to be encrypted.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Name-value pair that specifies the encryption context to be used for
    #   authenticated encryption. If used here, the same value must be
    #   supplied to the `Decrypt` API or decryption will fail. For more
    #   information, see [Encryption Context][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::EncryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::EncryptResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::EncryptResponse#key_id #key_id} => String
    #
    #
    # @example Example: To encrypt data
    #
    #   # The following example encrypts data with the specified customer master key (CMK).
    #
    #   resp = client.encrypt({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to use for encryption. You can use the key ID or Amazon Resource Name (ARN) of the CMK, or the name or ARN of an alias that refers to the CMK.
    #     plaintext: "<binary data>", # The data to encrypt.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data (ciphertext).
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that was used to encrypt the data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.encrypt({
    #     key_id: "KeyIdType", # required
    #     plaintext: "data", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Encrypt AWS API Documentation
    #
    # @overload encrypt(params = {})
    # @param [Hash] params ({})
    def encrypt(params = {}, options = {})
      req = build_request(:encrypt, params)
      req.send_request(options)
    end

    # Generates a unique data key. This operation returns a plaintext copy
    # of the data key and a copy that is encrypted under a customer master
    # key (CMK) that you specify. You can use the plaintext key to encrypt
    # your data outside of KMS and store the encrypted data key with the
    # encrypted data.
    #
    # `GenerateDataKey` returns a unique data key for each request. The
    # bytes in the key are not related to the caller or CMK that is used to
    # encrypt the data key.
    #
    # To generate a data key, you need to specify the customer master key
    # (CMK) that will be used to encrypt the data key. You must also specify
    # the length of the data key using either the `KeySpec` or
    # `NumberOfBytes` field (but not both). For common key lengths (128-bit
    # and 256-bit symmetric keys), we recommend that you use `KeySpec`. To
    # perform this operation on a CMK in a different AWS account, specify
    # the key ARN or alias ARN in the value of the KeyId parameter.
    #
    # You will find the plaintext copy of the data key in the `Plaintext`
    # field of the response, and the encrypted copy of the data key in the
    # `CiphertextBlob` field.
    #
    # We recommend that you use the following pattern to encrypt data
    # locally in your application:
    #
    # 1.  Use the `GenerateDataKey` operation to get a data encryption key.
    #
    # 2.  Use the plaintext data key (returned in the `Plaintext` field of
    #     the response) to encrypt data locally, then erase the plaintext
    #     data key from memory.
    #
    # 3.  Store the encrypted data key (returned in the `CiphertextBlob`
    #     field of the response) alongside the locally encrypted data.
    #
    # To decrypt data locally:
    #
    # 1.  Use the Decrypt operation to decrypt the encrypted data key. The
    #     operation returns a plaintext copy of the data key.
    #
    # 2.  Use the plaintext data key to decrypt data locally, then erase the
    #     plaintext data key from memory.
    #
    # To get only an encrypted copy of the data key, use
    # GenerateDataKeyWithoutPlaintext. To get a cryptographically secure
    # random byte string, use GenerateRandom.
    #
    # You can use the optional encryption context to add additional security
    # to your encryption operation. When you specify an `EncryptionContext`
    # in the `GenerateDataKey` operation, you must specify the same
    # encryption context (a case-sensitive exact match) in your request to
    # Decrypt the data key. Otherwise, the request to decrypt fails with an
    # `InvalidCiphertextException`. For more information, see [Encryption
    # Context][1] in the <i> <i>AWS Key Management Service Developer
    # Guide</i> </i>.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   An identifier for the CMK that encrypts the data key.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   A set of key-value pairs that represents additional authenticated
    #   data.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Integer] :number_of_bytes
    #   The length of the data key in bytes. For example, use the value 64 to
    #   generate a 512-bit data key (64 bytes is 512 bits). For common key
    #   lengths (128-bit and 256-bit symmetric keys), we recommend that you
    #   use the `KeySpec` field instead of this one.
    #
    # @option params [String] :key_spec
    #   The length of the data key. Use `AES_128` to generate a 128-bit
    #   symmetric key, or `AES_256` to generate a 256-bit symmetric key.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::GenerateDataKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::GenerateDataKeyResponse#plaintext #plaintext} => String
    #   * {Types::GenerateDataKeyResponse#key_id #key_id} => String
    #
    #
    # @example Example: To generate a data key
    #
    #   # The following example generates a 256-bit symmetric data encryption key (data key) in two formats. One is the
    #   # unencrypted (plainext) data key, and the other is the data key encrypted with the specified customer master key (CMK).
    #
    #   resp = client.generate_data_key({
    #     key_id: "alias/ExampleAlias", # The identifier of the CMK to use to encrypt the data key. You can use the key ID or Amazon Resource Name (ARN) of the CMK, or the name or ARN of an alias that refers to the CMK.
    #     key_spec: "AES_256", # Specifies the type of data key to return.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data key.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that was used to encrypt the data key.
    #     plaintext: "<binary data>", # The unencrypted (plaintext) data key.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key({
    #     key_id: "KeyIdType", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     number_of_bytes: 1,
    #     key_spec: "AES_256", # accepts AES_256, AES_128
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.plaintext #=> String
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKey AWS API Documentation
    #
    # @overload generate_data_key(params = {})
    # @param [Hash] params ({})
    def generate_data_key(params = {}, options = {})
      req = build_request(:generate_data_key, params)
      req.send_request(options)
    end

    # Generates a unique data key. This operation returns a data key that is
    # encrypted under a customer master key (CMK) that you specify.
    # `GenerateDataKeyWithoutPlaintext` is identical to GenerateDataKey
    # except that returns only the encrypted copy of the data key.
    #
    # Like `GenerateDataKey`, `GenerateDataKeyWithoutPlaintext` returns a
    # unique data key for each request. The bytes in the key are not related
    # to the caller or CMK that is used to encrypt the data key.
    #
    # This operation is useful for systems that need to encrypt data at some
    # point, but not immediately. When you need to encrypt the data, you
    # call the Decrypt operation on the encrypted copy of the key.
    #
    # It's also useful in distributed systems with different levels of
    # trust. For example, you might store encrypted data in containers. One
    # component of your system creates new containers and stores an
    # encrypted data key with each container. Then, a different component
    # puts the data into the containers. That component first decrypts the
    # data key, uses the plaintext data key to encrypt data, puts the
    # encrypted data into the container, and then destroys the plaintext
    # data key. In this system, the component that creates the containers
    # never sees the plaintext data key.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][1]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The identifier of the customer master key (CMK) that encrypts the data
    #   key.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   A set of key-value pairs that represents additional authenticated
    #   data.
    #
    #   For more information, see [Encryption Context][1] in the *AWS Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [String] :key_spec
    #   The length of the data key. Use `AES_128` to generate a 128-bit
    #   symmetric key, or `AES_256` to generate a 256-bit symmetric key.
    #
    # @option params [Integer] :number_of_bytes
    #   The length of the data key in bytes. For example, use the value 64 to
    #   generate a 512-bit data key (64 bytes is 512 bits). For common key
    #   lengths (128-bit and 256-bit symmetric keys), we recommend that you
    #   use the `KeySpec` field instead of this one.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::GenerateDataKeyWithoutPlaintextResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyWithoutPlaintextResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::GenerateDataKeyWithoutPlaintextResponse#key_id #key_id} => String
    #
    #
    # @example Example: To generate an encrypted data key
    #
    #   # The following example generates an encrypted copy of a 256-bit symmetric data encryption key (data key). The data key is
    #   # encrypted with the specified customer master key (CMK).
    #
    #   resp = client.generate_data_key_without_plaintext({
    #     key_id: "alias/ExampleAlias", # The identifier of the CMK to use to encrypt the data key. You can use the key ID or Amazon Resource Name (ARN) of the CMK, or the name or ARN of an alias that refers to the CMK.
    #     key_spec: "AES_256", # Specifies the type of data key to return.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data key.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that was used to encrypt the data key.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key_without_plaintext({
    #     key_id: "KeyIdType", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     key_spec: "AES_256", # accepts AES_256, AES_128
    #     number_of_bytes: 1,
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyWithoutPlaintext AWS API Documentation
    #
    # @overload generate_data_key_without_plaintext(params = {})
    # @param [Hash] params ({})
    def generate_data_key_without_plaintext(params = {}, options = {})
      req = build_request(:generate_data_key_without_plaintext, params)
      req.send_request(options)
    end

    # Returns a random byte string that is cryptographically secure.
    #
    # By default, the random byte string is generated in AWS KMS. To
    # generate the byte string in the AWS CloudHSM cluster that is
    # associated with a [custom key store][1], specify the custom key store
    # ID.
    #
    # For more information about entropy and random number generation, see
    # the [AWS Key Management Service Cryptographic Details][2] whitepaper.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf
    #
    # @option params [Integer] :number_of_bytes
    #   The length of the byte string.
    #
    # @option params [String] :custom_key_store_id
    #   Generates the random byte string in the AWS CloudHSM cluster that is
    #   associated with the specified [custom key store][1]. To find the ID of
    #   a custom key store, use the DescribeCustomKeyStores operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @return [Types::GenerateRandomResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateRandomResponse#plaintext #plaintext} => String
    #
    #
    # @example Example: To generate random data
    #
    #   # The following example uses AWS KMS to generate 32 bytes of random data.
    #
    #   resp = client.generate_random({
    #     number_of_bytes: 32, # The length of the random data, specified in number of bytes.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     plaintext: "<binary data>", # The random data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_random({
    #     number_of_bytes: 1,
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #   })
    #
    # @example Response structure
    #
    #   resp.plaintext #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateRandom AWS API Documentation
    #
    # @overload generate_random(params = {})
    # @param [Hash] params ({})
    def generate_random(params = {}, options = {})
      req = build_request(:generate_random, params)
      req.send_request(options)
    end

    # Gets a key policy attached to the specified customer master key (CMK).
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :policy_name
    #   Specifies the name of the key policy. The only valid name is
    #   `default`. To get the names of key policies, use ListKeyPolicies.
    #
    # @return [Types::GetKeyPolicyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetKeyPolicyResponse#policy #policy} => String
    #
    #
    # @example Example: To retrieve a key policy
    #
    #   # The following example retrieves the key policy for the specified customer master key (CMK).
    #
    #   resp = client.get_key_policy({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key policy you want to retrieve. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     policy_name: "default", # The name of the key policy to retrieve.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     policy: "{\n  \"Version\" : \"2012-10-17\",\n  \"Id\" : \"key-default-1\",\n  \"Statement\" : [ {\n    \"Sid\" : \"Enable IAM User Permissions\",\n    \"Effect\" : \"Allow\",\n    \"Principal\" : {\n      \"AWS\" : \"arn:aws:iam::111122223333:root\"\n    },\n    \"Action\" : \"kms:*\",\n    \"Resource\" : \"*\"\n  } ]\n}", # The key policy document.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_key_policy({
    #     key_id: "KeyIdType", # required
    #     policy_name: "PolicyNameType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.policy #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyPolicy AWS API Documentation
    #
    # @overload get_key_policy(params = {})
    # @param [Hash] params ({})
    def get_key_policy(params = {}, options = {})
      req = build_request(:get_key_policy, params)
      req.send_request(options)
    end

    # Gets a Boolean value that indicates whether [automatic rotation of the
    # key material][1] is enabled for the specified customer master key
    # (CMK).
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    # * Disabled: The key rotation status does not change when you disable a
    #   CMK. However, while the CMK is disabled, AWS KMS does not rotate the
    #   backing key.
    #
    # * Pending deletion: While a CMK is pending deletion, its key rotation
    #   status is `false` and AWS KMS does not rotate the backing key. If
    #   you cancel the deletion, the original key rotation status is
    #   restored.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN in the value of the `KeyId` parameter.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Types::GetKeyRotationStatusResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetKeyRotationStatusResponse#key_rotation_enabled #key_rotation_enabled} => Boolean
    #
    #
    # @example Example: To retrieve the rotation status for a customer master key (CMK)
    #
    #   # The following example retrieves the status of automatic annual rotation of the key material for the specified CMK.
    #
    #   resp = client.get_key_rotation_status({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key material rotation status you want to retrieve. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_rotation_enabled: true, # A boolean that indicates the key material rotation status. Returns true when automatic annual rotation of the key material is enabled, or false when it is not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_key_rotation_status({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.key_rotation_enabled #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyRotationStatus AWS API Documentation
    #
    # @overload get_key_rotation_status(params = {})
    # @param [Hash] params ({})
    def get_key_rotation_status(params = {}, options = {})
      req = build_request(:get_key_rotation_status, params)
      req.send_request(options)
    end

    # Returns the items you need in order to import key material into AWS
    # KMS from your existing key management infrastructure. For more
    # information about importing key material into AWS KMS, see [Importing
    # Key Material][1] in the *AWS Key Management Service Developer Guide*.
    #
    # You must specify the key ID of the customer master key (CMK) into
    # which you will import key material. This CMK's `Origin` must be
    # `EXTERNAL`. You must also specify the wrapping algorithm and type of
    # wrapping key (public key) that you will use to encrypt the key
    # material. You cannot perform this operation on a CMK in a different
    # AWS account.
    #
    # This operation returns a public key and an import token. Use the
    # public key to encrypt the key material. Store the import token to send
    # with a subsequent ImportKeyMaterial request. The public key and import
    # token from the same response must be used together. These items are
    # valid for 24 hours. When they expire, they cannot be used for a
    # subsequent ImportKeyMaterial request. To get new ones, send another
    # `GetParametersForImport` request.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The identifier of the CMK into which you will import key material. The
    #   CMK's `Origin` must be `EXTERNAL`.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :wrapping_algorithm
    #   The algorithm you will use to encrypt the key material before
    #   importing it with ImportKeyMaterial. For more information, see
    #   [Encrypt the Key Material][1] in the *AWS Key Management Service
    #   Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-encrypt-key-material.html
    #
    # @option params [required, String] :wrapping_key_spec
    #   The type of wrapping key (public key) to return in the response. Only
    #   2048-bit RSA public keys are supported.
    #
    # @return [Types::GetParametersForImportResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetParametersForImportResponse#key_id #key_id} => String
    #   * {Types::GetParametersForImportResponse#import_token #import_token} => String
    #   * {Types::GetParametersForImportResponse#public_key #public_key} => String
    #   * {Types::GetParametersForImportResponse#parameters_valid_to #parameters_valid_to} => Time
    #
    #
    # @example Example: To retrieve the public key and import token for a customer master key (CMK)
    #
    #   # The following example retrieves the public key and import token for the specified CMK.
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK for which to retrieve the public key and import token. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     wrapping_algorithm: "RSAES_OAEP_SHA_1", # The algorithm that you will use to encrypt the key material before importing it.
    #     wrapping_key_spec: "RSA_2048", # The type of wrapping key (public key) to return in the response.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     import_token: "<binary data>", # The import token to send with a subsequent ImportKeyMaterial request.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK for which you are retrieving the public key and import token. This is the same CMK specified in the request.
    #     parameters_valid_to: Time.parse("2016-12-01T14:52:17-08:00"), # The time at which the import token and public key are no longer valid.
    #     public_key: "<binary data>", # The public key to use to encrypt the key material before importing it.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "KeyIdType", # required
    #     wrapping_algorithm: "RSAES_PKCS1_V1_5", # required, accepts RSAES_PKCS1_V1_5, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256
    #     wrapping_key_spec: "RSA_2048", # required, accepts RSA_2048
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.import_token #=> String
    #   resp.public_key #=> String
    #   resp.parameters_valid_to #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetParametersForImport AWS API Documentation
    #
    # @overload get_parameters_for_import(params = {})
    # @param [Hash] params ({})
    def get_parameters_for_import(params = {}, options = {})
      req = build_request(:get_parameters_for_import, params)
      req.send_request(options)
    end

    # Imports key material into an existing AWS KMS customer master key
    # (CMK) that was created without key material. You cannot perform this
    # operation on a CMK in a different AWS account. For more information
    # about creating CMKs with no key material and then importing key
    # material, see [Importing Key Material][1] in the *AWS Key Management
    # Service Developer Guide*.
    #
    # Before using this operation, call GetParametersForImport. Its response
    # includes a public key and an import token. Use the public key to
    # encrypt the key material. Then, submit the import token from the same
    # `GetParametersForImport` response.
    #
    # When calling this operation, you must specify the following values:
    #
    # * The key ID or key ARN of a CMK with no key material. Its `Origin`
    #   must be `EXTERNAL`.
    #
    #   To create a CMK with no key material, call CreateKey and set the
    #   value of its `Origin` parameter to `EXTERNAL`. To get the `Origin`
    #   of a CMK, call DescribeKey.)
    #
    # * The encrypted key material. To get the public key to encrypt the key
    #   material, call GetParametersForImport.
    #
    # * The import token that GetParametersForImport returned. This token
    #   and the public key used to encrypt the key material must have come
    #   from the same response.
    #
    # * Whether the key material expires and if so, when. If you set an
    #   expiration date, you can change it only by reimporting the same key
    #   material and specifying a new expiration date. If the key material
    #   expires, AWS KMS deletes the key material and the CMK becomes
    #   unusable. To use the CMK again, you must reimport the same key
    #   material.
    #
    # When this operation is successful, the key state of the CMK changes
    # from `PendingImport` to `Enabled`, and you can use the CMK. After you
    # successfully import key material into a CMK, you can reimport the same
    # key material into that CMK, but you cannot import different key
    # material.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The identifier of the CMK to import the key material into. The CMK's
    #   `Origin` must be `EXTERNAL`.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String, IO] :import_token
    #   The import token that you received in the response to a previous
    #   GetParametersForImport request. It must be from the same response that
    #   contained the public key that you used to encrypt the key material.
    #
    # @option params [required, String, IO] :encrypted_key_material
    #   The encrypted key material to import. It must be encrypted with the
    #   public key that you received in the response to a previous
    #   GetParametersForImport request, using the wrapping algorithm that you
    #   specified in that request.
    #
    # @option params [Time,DateTime,Date,Integer,String] :valid_to
    #   The time at which the imported key material expires. When the key
    #   material expires, AWS KMS deletes the key material and the CMK becomes
    #   unusable. You must omit this parameter when the `ExpirationModel`
    #   parameter is set to `KEY_MATERIAL_DOES_NOT_EXPIRE`. Otherwise it is
    #   required.
    #
    # @option params [String] :expiration_model
    #   Specifies whether the key material expires. The default is
    #   `KEY_MATERIAL_EXPIRES`, in which case you must include the `ValidTo`
    #   parameter. When this parameter is set to
    #   `KEY_MATERIAL_DOES_NOT_EXPIRE`, you must omit the `ValidTo` parameter.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To import key material into a customer master key (CMK)
    #
    #   # The following example imports key material into the specified CMK.
    #
    #   resp = client.import_key_material({
    #     encrypted_key_material: "<binary data>", # The encrypted key material to import.
    #     expiration_model: "KEY_MATERIAL_DOES_NOT_EXPIRE", # A value that specifies whether the key material expires.
    #     import_token: "<binary data>", # The import token that you received in the response to a previous GetParametersForImport request.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to import the key material into. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.import_key_material({
    #     key_id: "KeyIdType", # required
    #     import_token: "data", # required
    #     encrypted_key_material: "data", # required
    #     valid_to: Time.now,
    #     expiration_model: "KEY_MATERIAL_EXPIRES", # accepts KEY_MATERIAL_EXPIRES, KEY_MATERIAL_DOES_NOT_EXPIRE
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ImportKeyMaterial AWS API Documentation
    #
    # @overload import_key_material(params = {})
    # @param [Hash] params ({})
    def import_key_material(params = {}, options = {})
      req = build_request(:import_key_material, params)
      req.send_request(options)
    end

    # Gets a list of aliases in the caller's AWS account and region. You
    # cannot list aliases in other accounts. For more information about
    # aliases, see CreateAlias.
    #
    # By default, the ListAliases command returns all aliases in the account
    # and region. To get only the aliases that point to a particular
    # customer master key (CMK), use the `KeyId` parameter.
    #
    # The `ListAliases` response can include aliases that you created and
    # associated with your customer managed CMKs, and aliases that AWS
    # created and associated with AWS managed CMKs in your account. You can
    # recognize AWS aliases because their names have the format
    # `aws/<service-name>`, such as `aws/dynamodb`.
    #
    # The response might also include aliases that have no `TargetKeyId`
    # field. These are predefined aliases that AWS has created but has not
    # yet associated with a CMK. Aliases that AWS creates in your account,
    # including predefined aliases, do not count against your [AWS KMS
    # aliases limit][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit
    #
    # @option params [String] :key_id
    #   Lists only aliases that refer to the specified CMK. The value of this
    #   parameter can be the ID or Amazon Resource Name (ARN) of a CMK in the
    #   caller's account and region. You cannot use an alias name or alias
    #   ARN in this value.
    #
    #   This parameter is optional. If you omit it, `ListAliases` returns all
    #   aliases in the account and region.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListAliasesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListAliasesResponse#aliases #aliases} => Array&lt;Types::AliasListEntry&gt;
    #   * {Types::ListAliasesResponse#next_marker #next_marker} => String
    #   * {Types::ListAliasesResponse#truncated #truncated} => Boolean
    #
    #
    # @example Example: To list aliases
    #
    #   # The following example lists aliases.
    #
    #   resp = client.list_aliases({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     aliases: [
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/acm", 
    #         alias_name: "alias/aws/acm", 
    #         target_key_id: "da03f6f7-d279-427a-9cae-de48d07e5b66", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/ebs", 
    #         alias_name: "alias/aws/ebs", 
    #         target_key_id: "25a217e7-7170-4b8c-8bf6-045ea5f70e5b", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/rds", 
    #         alias_name: "alias/aws/rds", 
    #         target_key_id: "7ec3104e-c3f2-4b5c-bf42-bfc4772c6685", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/redshift", 
    #         alias_name: "alias/aws/redshift", 
    #         target_key_id: "08f7a25a-69e2-4fb5-8f10-393db27326fa", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/s3", 
    #         alias_name: "alias/aws/s3", 
    #         target_key_id: "d2b0f1a3-580d-4f79-b836-bc983be8cfa5", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example1", 
    #         alias_name: "alias/example1", 
    #         target_key_id: "4da1e216-62d0-46c5-a7c0-5f3a3d2f8046", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example2", 
    #         alias_name: "alias/example2", 
    #         target_key_id: "f32fef59-2cc2-445b-8573-2d73328acbee", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example3", 
    #         alias_name: "alias/example3", 
    #         target_key_id: "1374ef38-d34e-4d5f-b2c9-4e0daee38855", 
    #       }, 
    #     ], # A list of aliases, including the key ID of the customer master key (CMK) that each alias refers to.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_aliases({
    #     key_id: "KeyIdType",
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.aliases #=> Array
    #   resp.aliases[0].alias_name #=> String
    #   resp.aliases[0].alias_arn #=> String
    #   resp.aliases[0].target_key_id #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListAliases AWS API Documentation
    #
    # @overload list_aliases(params = {})
    # @param [Hash] params ({})
    def list_aliases(params = {}, options = {})
      req = build_request(:list_aliases, params)
      req.send_request(options)
    end

    # Gets a list of all grants for the specified customer master key (CMK).
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN in the value of the `KeyId` parameter.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @return [Types::ListGrantsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListGrantsResponse#grants #grants} => Array&lt;Types::GrantListEntry&gt;
    #   * {Types::ListGrantsResponse#next_marker #next_marker} => String
    #   * {Types::ListGrantsResponse#truncated #truncated} => Boolean
    #
    #
    # @example Example: To list grants for a customer master key (CMK)
    #
    #   # The following example lists grants for the specified CMK.
    #
    #   resp = client.list_grants({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose grants you want to list. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grants: [
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "91ad875e49b04a9d1f3bdeb84d821f9db6ea95e1098813f6d47f0c65fbe2a172", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "a5d67d3e207a8fc1f4928749ee3e52eb0440493a8b9cf05bbfad91655b056200", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "c541aaf05d90cb78846a73b346fc43e65be28b7163129488c738e0c9e0628f4f", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "dd2052c67b4c76ee45caf1dc6a1e2d24e8dc744a51b36ae2f067dc540ce0105c", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #     ], # A list of grants.
    #     truncated: true, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_grants({
    #     limit: 1,
    #     marker: "MarkerType",
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.grants #=> Array
    #   resp.grants[0].key_id #=> String
    #   resp.grants[0].grant_id #=> String
    #   resp.grants[0].name #=> String
    #   resp.grants[0].creation_date #=> Time
    #   resp.grants[0].grantee_principal #=> String
    #   resp.grants[0].retiring_principal #=> String
    #   resp.grants[0].issuing_account #=> String
    #   resp.grants[0].operations #=> Array
    #   resp.grants[0].operations[0] #=> String, one of "Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncryptFrom", "ReEncryptTo", "CreateGrant", "RetireGrant", "DescribeKey"
    #   resp.grants[0].constraints.encryption_context_subset #=> Hash
    #   resp.grants[0].constraints.encryption_context_subset["EncryptionContextKey"] #=> String
    #   resp.grants[0].constraints.encryption_context_equals #=> Hash
    #   resp.grants[0].constraints.encryption_context_equals["EncryptionContextKey"] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListGrants AWS API Documentation
    #
    # @overload list_grants(params = {})
    # @param [Hash] params ({})
    def list_grants(params = {}, options = {})
      req = build_request(:list_grants, params)
      req.send_request(options)
    end

    # Gets the names of the key policies that are attached to a customer
    # master key (CMK). This operation is designed to get policy names that
    # you can use in a GetKeyPolicy operation. However, the only valid
    # policy name is `default`. You cannot perform this operation on a CMK
    # in a different AWS account.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #
    #   Only one policy can be attached to a key.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListKeyPoliciesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListKeyPoliciesResponse#policy_names #policy_names} => Array&lt;String&gt;
    #   * {Types::ListKeyPoliciesResponse#next_marker #next_marker} => String
    #   * {Types::ListKeyPoliciesResponse#truncated #truncated} => Boolean
    #
    #
    # @example Example: To list key policies for a customer master key (CMK)
    #
    #   # The following example lists key policies for the specified CMK.
    #
    #   resp = client.list_key_policies({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose key policies you want to list. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     policy_names: [
    #       "default", 
    #     ], # A list of key policy names.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_key_policies({
    #     key_id: "KeyIdType", # required
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.policy_names #=> Array
    #   resp.policy_names[0] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeyPolicies AWS API Documentation
    #
    # @overload list_key_policies(params = {})
    # @param [Hash] params ({})
    def list_key_policies(params = {}, options = {})
      req = build_request(:list_key_policies, params)
      req.send_request(options)
    end

    # Gets a list of all customer master keys (CMKs) in the caller's AWS
    # account and region.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListKeysResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListKeysResponse#keys #keys} => Array&lt;Types::KeyListEntry&gt;
    #   * {Types::ListKeysResponse#next_marker #next_marker} => String
    #   * {Types::ListKeysResponse#truncated #truncated} => Boolean
    #
    #
    # @example Example: To list customer master keys (CMKs)
    #
    #   # The following example lists CMKs.
    #
    #   resp = client.list_keys({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     keys: [
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/0d990263-018e-4e65-a703-eff731de951e", 
    #         key_id: "0d990263-018e-4e65-a703-eff731de951e", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/144be297-0ae1-44ac-9c8f-93cd8c82f841", 
    #         key_id: "144be297-0ae1-44ac-9c8f-93cd8c82f841", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/21184251-b765-428e-b852-2c7353e72571", 
    #         key_id: "21184251-b765-428e-b852-2c7353e72571", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/214fe92f-5b03-4ae1-b350-db2a45dbe10c", 
    #         key_id: "214fe92f-5b03-4ae1-b350-db2a45dbe10c", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/339963f2-e523-49d3-af24-a0fe752aa458", 
    #         key_id: "339963f2-e523-49d3-af24-a0fe752aa458", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/b776a44b-df37-4438-9be4-a27494e4271a", 
    #         key_id: "b776a44b-df37-4438-9be4-a27494e4271a", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/deaf6c9e-cf2c-46a6-bf6d-0b6d487cffbb", 
    #         key_id: "deaf6c9e-cf2c-46a6-bf6d-0b6d487cffbb", 
    #       }, 
    #     ], # A list of CMKs, including the key ID and Amazon Resource Name (ARN) of each one.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_keys({
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.keys #=> Array
    #   resp.keys[0].key_id #=> String
    #   resp.keys[0].key_arn #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeys AWS API Documentation
    #
    # @overload list_keys(params = {})
    # @param [Hash] params ({})
    def list_keys(params = {}, options = {})
      req = build_request(:list_keys, params)
      req.send_request(options)
    end

    # Returns a list of all tags for the specified customer master key
    # (CMK).
    #
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 50, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    #   Do not attempt to construct this value. Use only the value of
    #   `NextMarker` from the truncated response you just received.
    #
    # @return [Types::ListResourceTagsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListResourceTagsResponse#tags #tags} => Array&lt;Types::Tag&gt;
    #   * {Types::ListResourceTagsResponse#next_marker #next_marker} => String
    #   * {Types::ListResourceTagsResponse#truncated #truncated} => Boolean
    #
    #
    # @example Example: To list tags for a customer master key (CMK)
    #
    #   # The following example lists tags for a CMK.
    #
    #   resp = client.list_resource_tags({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose tags you are listing. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     tags: [
    #       {
    #         tag_key: "CostCenter", 
    #         tag_value: "87654", 
    #       }, 
    #       {
    #         tag_key: "CreatedBy", 
    #         tag_value: "ExampleUser", 
    #       }, 
    #       {
    #         tag_key: "Purpose", 
    #         tag_value: "Test", 
    #       }, 
    #     ], # A list of tags.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_resource_tags({
    #     key_id: "KeyIdType", # required
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.tags #=> Array
    #   resp.tags[0].tag_key #=> String
    #   resp.tags[0].tag_value #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListResourceTags AWS API Documentation
    #
    # @overload list_resource_tags(params = {})
    # @param [Hash] params ({})
    def list_resource_tags(params = {}, options = {})
      req = build_request(:list_resource_tags, params)
      req.send_request(options)
    end

    # Returns a list of all grants for which the grant's
    # `RetiringPrincipal` matches the one specified.
    #
    # A typical use is to list all grants that you are able to retire. To
    # retire a grant, use RetireGrant.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, AWS KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @option params [required, String] :retiring_principal
    #   The retiring principal for which to list grants.
    #
    #   To specify the retiring principal, use the [Amazon Resource Name
    #   (ARN)][1] of an AWS principal. Valid AWS principals include AWS
    #   accounts (root), IAM users, federated users, and assumed role users.
    #   For examples of the ARN syntax for specifying a principal, see [AWS
    #   Identity and Access Management (IAM)][2] in the Example ARNs section
    #   of the *Amazon Web Services General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#arn-syntax-iam
    #
    # @return [Types::ListGrantsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListGrantsResponse#grants #grants} => Array&lt;Types::GrantListEntry&gt;
    #   * {Types::ListGrantsResponse#next_marker #next_marker} => String
    #   * {Types::ListGrantsResponse#truncated #truncated} => Boolean
    #
    #
    # @example Example: To list grants that the specified principal can retire
    #
    #   # The following example lists the grants that the specified principal (identity) can retire.
    #
    #   resp = client.list_retirable_grants({
    #     retiring_principal: "arn:aws:iam::111122223333:role/ExampleRole", # The retiring principal whose grants you want to list. Use the Amazon Resource Name (ARN) of an AWS principal such as an AWS account (root), IAM user, federated user, or assumed role user.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grants: [
    #       {
    #         creation_date: Time.parse("2016-12-07T11:09:35-08:00"), 
    #         grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", 
    #         grantee_principal: "arn:aws:iam::111122223333:role/ExampleRole", 
    #         issuing_account: "arn:aws:iam::444455556666:root", 
    #         key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Decrypt", 
    #           "Encrypt", 
    #         ], 
    #         retiring_principal: "arn:aws:iam::111122223333:role/ExampleRole", 
    #       }, 
    #     ], # A list of grants that the specified principal can retire.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_retirable_grants({
    #     limit: 1,
    #     marker: "MarkerType",
    #     retiring_principal: "PrincipalIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.grants #=> Array
    #   resp.grants[0].key_id #=> String
    #   resp.grants[0].grant_id #=> String
    #   resp.grants[0].name #=> String
    #   resp.grants[0].creation_date #=> Time
    #   resp.grants[0].grantee_principal #=> String
    #   resp.grants[0].retiring_principal #=> String
    #   resp.grants[0].issuing_account #=> String
    #   resp.grants[0].operations #=> Array
    #   resp.grants[0].operations[0] #=> String, one of "Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncryptFrom", "ReEncryptTo", "CreateGrant", "RetireGrant", "DescribeKey"
    #   resp.grants[0].constraints.encryption_context_subset #=> Hash
    #   resp.grants[0].constraints.encryption_context_subset["EncryptionContextKey"] #=> String
    #   resp.grants[0].constraints.encryption_context_equals #=> Hash
    #   resp.grants[0].constraints.encryption_context_equals["EncryptionContextKey"] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListRetirableGrants AWS API Documentation
    #
    # @overload list_retirable_grants(params = {})
    # @param [Hash] params ({})
    def list_retirable_grants(params = {}, options = {})
      req = build_request(:list_retirable_grants, params)
      req.send_request(options)
    end

    # Attaches a key policy to the specified customer master key (CMK). You
    # cannot perform this operation on a CMK in a different AWS account.
    #
    # For more information about key policies, see [Key Policies][1] in the
    # *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :policy_name
    #   The name of the key policy. The only valid value is `default`.
    #
    # @option params [required, String] :policy
    #   The key policy to attach to the CMK.
    #
    #   The key policy must meet the following criteria:
    #
    #   * If you don't set `BypassPolicyLockoutSafetyCheck` to true, the key
    #     policy must allow the principal that is making the `PutKeyPolicy`
    #     request to make a subsequent `PutKeyPolicy` request on the CMK. This
    #     reduces the risk that the CMK becomes unmanageable. For more
    #     information, refer to the scenario in the [Default Key Policy][1]
    #     section of the *AWS Key Management Service Developer Guide*.
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to AWS KMS. When you create a new AWS principal (for
    #     example, an IAM user or role), you might need to enforce a delay
    #     before including the new principal in a key policy because the new
    #     principal might not be immediately visible to AWS KMS. For more
    #     information, see [Changes that I make are not always immediately
    #     visible][2] in the *AWS Identity and Access Management User Guide*.
    #
    #   The key policy size limit is 32 kilobytes (32768 bytes).
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #
    # @option params [Boolean] :bypass_policy_lockout_safety_check
    #   A flag to indicate whether to bypass the key policy lockout safety
    #   check.
    #
    #   Setting this value to true increases the risk that the CMK becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, refer to the scenario in the [Default Key
    #   Policy][1] section in the *AWS Key Management Service Developer
    #   Guide*.
    #
    #   Use this parameter only when you intend to prevent the principal that
    #   is making the request from making a subsequent `PutKeyPolicy` request
    #   on the CMK.
    #
    #   The default value is false.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-root-enable-iam
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To attach a key policy to a customer master key (CMK)
    #
    #   # The following example attaches a key policy to the specified CMK.
    #
    #   resp = client.put_key_policy({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to attach the key policy to. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     policy: "{\"Version\":\"2012-10-17\",\"Id\":\"custom-policy-2016-12-07\",\"Statement\":[{\"Sid\":\"EnableIAMUserPermissions\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:root\"},\"Action\":\"kms:*\",\"Resource\":\"*\"},{\"Sid\":\"AllowaccessforKeyAdministrators\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":[\"arn:aws:iam::111122223333:user/ExampleAdminUser\",\"arn:aws:iam::111122223333:role/ExampleAdminRole\"]},\"Action\":[\"kms:Create*\",\"kms:Describe*\",\"kms:Enable*\",\"kms:List*\",\"kms:Put*\",\"kms:Update*\",\"kms:Revoke*\",\"kms:Disable*\",\"kms:Get*\",\"kms:Delete*\",\"kms:ScheduleKeyDeletion\",\"kms:CancelKeyDeletion\"],\"Resource\":\"*\"},{\"Sid\":\"Allowuseofthekey\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:role/ExamplePowerUserRole\"},\"Action\":[\"kms:Encrypt\",\"kms:Decrypt\",\"kms:ReEncrypt*\",\"kms:GenerateDataKey*\",\"kms:DescribeKey\"],\"Resource\":\"*\"},{\"Sid\":\"Allowattachmentofpersistentresources\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:role/ExamplePowerUserRole\"},\"Action\":[\"kms:CreateGrant\",\"kms:ListGrants\",\"kms:RevokeGrant\"],\"Resource\":\"*\",\"Condition\":{\"Bool\":{\"kms:GrantIsForAWSResource\":\"true\"}}}]}", # The key policy document.
    #     policy_name: "default", # The name of the key policy.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_key_policy({
    #     key_id: "KeyIdType", # required
    #     policy_name: "PolicyNameType", # required
    #     policy: "PolicyType", # required
    #     bypass_policy_lockout_safety_check: false,
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/PutKeyPolicy AWS API Documentation
    #
    # @overload put_key_policy(params = {})
    # @param [Hash] params ({})
    def put_key_policy(params = {}, options = {})
      req = build_request(:put_key_policy, params)
      req.send_request(options)
    end

    # Encrypts data on the server side with a new customer master key (CMK)
    # without exposing the plaintext of the data on the client side. The
    # data is first decrypted and then reencrypted. You can also use this
    # operation to change the encryption context of a ciphertext.
    #
    # You can reencrypt data using CMKs in different AWS accounts.
    #
    # Unlike other operations, `ReEncrypt` is authorized twice, once as
    # `ReEncryptFrom` on the source CMK and once as `ReEncryptTo` on the
    # destination CMK. We recommend that you include the `"kms:ReEncrypt*"`
    # permission in your [key policies][1] to permit reencryption from or to
    # the CMK. This permission is automatically included in the key policy
    # when you create a CMK through the console. But you must include it
    # manually when you create a CMK programmatically or when you set a key
    # policy with the PutKeyPolicy operation.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String, IO] :ciphertext_blob
    #   Ciphertext of the data to reencrypt.
    #
    # @option params [Hash<String,String>] :source_encryption_context
    #   Encryption context used to encrypt and decrypt the data specified in
    #   the `CiphertextBlob` parameter.
    #
    # @option params [required, String] :destination_key_id
    #   A unique identifier for the CMK that is used to reencrypt the data.
    #
    #   To specify a CMK, use its key ID, Amazon Resource Name (ARN), alias
    #   name, or alias ARN. When using an alias name, prefix it with
    #   `"alias/"`. To specify a CMK in a different AWS account, you must use
    #   the key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #   To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :destination_encryption_context
    #   Encryption context to use when the data is reencrypted.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   For more information, see [Grant Tokens][1] in the *AWS Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#grant_token
    #
    # @return [Types::ReEncryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ReEncryptResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::ReEncryptResponse#source_key_id #source_key_id} => String
    #   * {Types::ReEncryptResponse#key_id #key_id} => String
    #
    #
    # @example Example: To reencrypt data
    #
    #   # The following example reencrypts data with the specified CMK.
    #
    #   resp = client.re_encrypt({
    #     ciphertext_blob: "<binary data>", # The data to reencrypt.
    #     destination_key_id: "0987dcba-09fe-87dc-65ba-ab0987654321", # The identifier of the CMK to use to reencrypt the data. You can use the key ID or Amazon Resource Name (ARN) of the CMK, or the name or ARN of an alias that refers to the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The reencrypted data.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The ARN of the CMK that was used to reencrypt the data.
    #     source_key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that was used to originally encrypt the data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.re_encrypt({
    #     ciphertext_blob: "data", # required
    #     source_encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     destination_key_id: "KeyIdType", # required
    #     destination_encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.source_key_id #=> String
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ReEncrypt AWS API Documentation
    #
    # @overload re_encrypt(params = {})
    # @param [Hash] params ({})
    def re_encrypt(params = {}, options = {})
      req = build_request(:re_encrypt, params)
      req.send_request(options)
    end

    # Retires a grant. To clean up, you can retire a grant when you're done
    # using it. You should revoke a grant when you intend to actively deny
    # operations that depend on it. The following are permitted to call this
    # API:
    #
    # * The AWS account (root user) under which the grant was created
    #
    # * The `RetiringPrincipal`, if present in the grant
    #
    # * The `GranteePrincipal`, if `RetireGrant` is an operation specified
    #   in the grant
    #
    # You must identify the grant to retire by its grant token or by a
    # combination of the grant ID and the Amazon Resource Name (ARN) of the
    # customer master key (CMK). A grant token is a unique variable-length
    # base64-encoded string. A grant ID is a 64 character unique identifier
    # of a grant. The CreateGrant operation returns both.
    #
    # @option params [String] :grant_token
    #   Token that identifies the grant to be retired.
    #
    # @option params [String] :key_id
    #   The Amazon Resource Name (ARN) of the CMK associated with the grant.
    #
    #   For example:
    #   `arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    # @option params [String] :grant_id
    #   Unique identifier of the grant to retire. The grant ID is returned in
    #   the response to a `CreateGrant` operation.
    #
    #   * Grant ID Example -
    #     0123456789012345678901234567890123456789012345678901234567890123
    #
    #   ^
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To retire a grant
    #
    #   # The following example retires a grant.
    #
    #   resp = client.retire_grant({
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The identifier of the grant to retire.
    #     key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The Amazon Resource Name (ARN) of the customer master key (CMK) associated with the grant.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.retire_grant({
    #     grant_token: "GrantTokenType",
    #     key_id: "KeyIdType",
    #     grant_id: "GrantIdType",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RetireGrant AWS API Documentation
    #
    # @overload retire_grant(params = {})
    # @param [Hash] params ({})
    def retire_grant(params = {}, options = {})
      req = build_request(:retire_grant, params)
      req.send_request(options)
    end

    # Revokes the specified grant for the specified customer master key
    # (CMK). You can revoke a grant to actively deny operations that depend
    # on it.
    #
    # To perform this operation on a CMK in a different AWS account, specify
    # the key ARN in the value of the `KeyId` parameter.
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key associated with the
    #   grant.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK. To
    #   specify a CMK in a different AWS account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :grant_id
    #   Identifier of the grant to be revoked.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To revoke a grant
    #
    #   # The following example revokes a grant.
    #
    #   resp = client.revoke_grant({
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The identifier of the grant to revoke.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the customer master key (CMK) associated with the grant. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.revoke_grant({
    #     key_id: "KeyIdType", # required
    #     grant_id: "GrantIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RevokeGrant AWS API Documentation
    #
    # @overload revoke_grant(params = {})
    # @param [Hash] params ({})
    def revoke_grant(params = {}, options = {})
      req = build_request(:revoke_grant, params)
      req.send_request(options)
    end

    # Schedules the deletion of a customer master key (CMK). You may provide
    # a waiting period, specified in days, before deletion occurs. If you do
    # not provide a waiting period, the default period of 30 days is used.
    # When this operation is successful, the key state of the CMK changes to
    # `PendingDeletion`. Before the waiting period ends, you can use
    # CancelKeyDeletion to cancel the deletion of the CMK. After the waiting
    # period ends, AWS KMS deletes the CMK and all AWS KMS data associated
    # with it, including all aliases that refer to it.
    #
    # Deleting a CMK is a destructive and potentially dangerous operation.
    # When a CMK is deleted, all data that was encrypted under the CMK is
    # unrecoverable. To prevent the use of a CMK without deleting it, use
    # DisableKey.
    #
    # If you schedule deletion of a CMK from a [custom key store][1], when
    # the waiting period expires, `ScheduleKeyDeletion` deletes the CMK from
    # AWS KMS. Then AWS KMS makes a best effort to delete the key material
    # from the associated AWS CloudHSM cluster. However, you might need to
    # manually [delete the orphaned key material][2] from the cluster and
    # its backups.
    #
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # For more information about scheduling a CMK for deletion, see
    # [Deleting Customer Master Keys][3] in the *AWS Key Management Service
    # Developer Guide*.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][4]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   The unique identifier of the customer master key (CMK) to delete.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [Integer] :pending_window_in_days
    #   The waiting period, specified in number of days. After the waiting
    #   period ends, AWS KMS deletes the customer master key (CMK).
    #
    #   This value is optional. If you include a value, it must be between 7
    #   and 30, inclusive. If you do not include a value, it defaults to 30.
    #
    # @return [Types::ScheduleKeyDeletionResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ScheduleKeyDeletionResponse#key_id #key_id} => String
    #   * {Types::ScheduleKeyDeletionResponse#deletion_date #deletion_date} => Time
    #
    #
    # @example Example: To schedule a customer master key (CMK) for deletion
    #
    #   # The following example schedules the specified CMK for deletion.
    #
    #   resp = client.schedule_key_deletion({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK to schedule for deletion. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     pending_window_in_days: 7, # The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the CMK.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     deletion_date: Time.parse("2016-12-17T16:00:00-08:00"), # The date and time after which AWS KMS deletes the CMK.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the CMK that is scheduled for deletion.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.schedule_key_deletion({
    #     key_id: "KeyIdType", # required
    #     pending_window_in_days: 1,
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.deletion_date #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ScheduleKeyDeletion AWS API Documentation
    #
    # @overload schedule_key_deletion(params = {})
    # @param [Hash] params ({})
    def schedule_key_deletion(params = {}, options = {})
      req = build_request(:schedule_key_deletion, params)
      req.send_request(options)
    end

    # Adds or edits tags for a customer master key (CMK). You cannot perform
    # this operation on a CMK in a different AWS account.
    #
    # Each tag consists of a tag key and a tag value. Tag keys and tag
    # values are both required, but tag values can be empty (null) strings.
    #
    # You can only use a tag key once for each CMK. If you use the tag key
    # again, AWS KMS replaces the current tag value with the specified
    # value.
    #
    # For information about the rules that apply to tag keys and tag values,
    # see [User-Defined Tag Restrictions][1] in the *AWS Billing and Cost
    # Management User Guide*.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the CMK you are tagging.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, Array<Types::Tag>] :tags
    #   One or more tags. Each tag consists of a tag key and a tag value.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To tag a customer master key (CMK)
    #
    #   # The following example tags a CMK.
    #
    #   resp = client.tag_resource({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK you are tagging. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #     tags: [
    #       {
    #         tag_key: "Purpose", 
    #         tag_value: "Test", 
    #       }, 
    #     ], # A list of tags.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.tag_resource({
    #     key_id: "KeyIdType", # required
    #     tags: [ # required
    #       {
    #         tag_key: "TagKeyType", # required
    #         tag_value: "TagValueType", # required
    #       },
    #     ],
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/TagResource AWS API Documentation
    #
    # @overload tag_resource(params = {})
    # @param [Hash] params ({})
    def tag_resource(params = {}, options = {})
      req = build_request(:tag_resource, params)
      req.send_request(options)
    end

    # Removes the specified tags from the specified customer master key
    # (CMK). You cannot perform this operation on a CMK in a different AWS
    # account.
    #
    # To remove a tag, specify the tag key. To change the tag value of an
    # existing tag key, use TagResource.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][1]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the CMK from which you are removing tags.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, Array<String>] :tag_keys
    #   One or more tag keys. Specify only the tag keys, not the tag values.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To remove tags from a customer master key (CMK)
    #
    #   # The following example removes tags from a CMK.
    #
    #   resp = client.untag_resource({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose tags you are removing.
    #     tag_keys: [
    #       "Purpose", 
    #       "CostCenter", 
    #     ], # A list of tag keys. Provide only the tag keys, not the tag values.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.untag_resource({
    #     key_id: "KeyIdType", # required
    #     tag_keys: ["TagKeyType"], # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UntagResource AWS API Documentation
    #
    # @overload untag_resource(params = {})
    # @param [Hash] params ({})
    def untag_resource(params = {}, options = {})
      req = build_request(:untag_resource, params)
      req.send_request(options)
    end

    # Associates an existing alias with a different customer master key
    # (CMK). Each CMK can have multiple aliases, but the aliases must be
    # unique within the account and region. You cannot perform this
    # operation on an alias in a different AWS account.
    #
    # This operation works only on existing aliases. To change the alias of
    # a CMK to a new value, use CreateAlias to create a new alias and
    # DeleteAlias to delete the old alias.
    #
    # Because an alias is not a property of a CMK, you can create, update,
    # and delete the aliases of a CMK without affecting the CMK. Also,
    # aliases do not appear in the response from the DescribeKey operation.
    # To get the aliases of all CMKs in the account, use the ListAliases
    # operation.
    #
    # The alias name must begin with `alias/` followed by a name, such as
    # `alias/ExampleAlias`. It can contain only alphanumeric characters,
    # forward slashes (/), underscores (\_), and dashes (-). The alias name
    # cannot begin with `alias/aws/`. The `alias/aws/` prefix is reserved
    # for [AWS managed CMKs][1].
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][2]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :alias_name
    #   Specifies the name of the alias to change. This value must begin with
    #   `alias/` followed by the alias name, such as `alias/ExampleAlias`.
    #
    # @option params [required, String] :target_key_id
    #   Unique identifier of the customer master key (CMK) to be mapped to the
    #   alias. When the update operation completes, the alias will point to
    #   this CMK.
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    #   To verify that the alias is mapped to the correct CMK, use
    #   ListAliases.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To update an alias
    #
    #   # The following example updates the specified alias to refer to the specified customer master key (CMK).
    #
    #   resp = client.update_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to update.
    #     target_key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK that the alias will refer to after this operation succeeds. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_alias({
    #     alias_name: "AliasNameType", # required
    #     target_key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateAlias AWS API Documentation
    #
    # @overload update_alias(params = {})
    # @param [Hash] params ({})
    def update_alias(params = {}, options = {})
      req = build_request(:update_alias, params)
      req.send_request(options)
    end

    # Changes the properties of a custom key store. Use the
    # `CustomKeyStoreId` parameter to identify the custom key store you want
    # to edit. Use the remaining parameters to change the properties of the
    # custom key store.
    #
    # You can only update a custom key store that is disconnected. To
    # disconnect the custom key store, use DisconnectCustomKeyStore. To
    # reconnect the custom key store after the update completes, use
    # ConnectCustomKeyStore. To find the connection state of a custom key
    # store, use the DescribeCustomKeyStores operation.
    #
    # Use the parameters of `UpdateCustomKeyStore` to edit your keystore
    # settings.
    #
    # * Use the **NewCustomKeyStoreName** parameter to change the friendly
    #   name of the custom key store to the value that you specify.
    #
    #
    #
    # * Use the **KeyStorePassword** parameter tell AWS KMS the current
    #   password of the [ `kmsuser` crypto user (CU)][1] in the associated
    #   AWS CloudHSM cluster. You can use this parameter to [fix connection
    #   failures][2] that occur when AWS KMS cannot log into the associated
    #   cluster because the `kmsuser` password has changed. This value does
    #   not change the password in the AWS CloudHSM cluster.
    #
    #
    #
    # * Use the **CloudHsmClusterId** parameter to associate the custom key
    #   store with a different, but related, AWS CloudHSM cluster. You can
    #   use this parameter to repair a custom key store if its AWS CloudHSM
    #   cluster becomes corrupted or is deleted, or when you need to create
    #   or restore a cluster from a backup.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # This operation is part of the [Custom Key Store feature][3] feature in
    # AWS KMS, which combines the convenience and extensive integration of
    # AWS KMS with the isolation and control of a single-tenant key store.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html
    #
    # @option params [required, String] :custom_key_store_id
    #   Identifies the custom key store that you want to update. Enter the ID
    #   of the custom key store. To find the ID of a custom key store, use the
    #   DescribeCustomKeyStores operation.
    #
    # @option params [String] :new_custom_key_store_name
    #   Changes the friendly name of the custom key store to the value that
    #   you specify. The custom key store name must be unique in the AWS
    #   account.
    #
    # @option params [String] :key_store_password
    #   Enter the current password of the `kmsuser` crypto user (CU) in the
    #   AWS CloudHSM cluster that is associated with the custom key store.
    #
    #   This parameter tells AWS KMS the current password of the `kmsuser`
    #   crypto user (CU). It does not set or change the password of any users
    #   in the AWS CloudHSM cluster.
    #
    # @option params [String] :cloud_hsm_cluster_id
    #   Associates the custom key store with a related AWS CloudHSM cluster.
    #
    #   Enter the cluster ID of the cluster that you used to create the custom
    #   key store or a cluster that shares a backup history and has the same
    #   cluster certificate as the original cluster. You cannot use this
    #   parameter to associate a custom key store with an unrelated cluster.
    #   In addition, the replacement cluster must [fulfill the
    #   requirements][1] for a cluster associated with a custom key store. To
    #   view the cluster certificate of a cluster, use the
    #   [DescribeClusters][2] operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore
    #   [2]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #     new_custom_key_store_name: "CustomKeyStoreNameType",
    #     key_store_password: "KeyStorePasswordType",
    #     cloud_hsm_cluster_id: "CloudHsmClusterIdType",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateCustomKeyStore AWS API Documentation
    #
    # @overload update_custom_key_store(params = {})
    # @param [Hash] params ({})
    def update_custom_key_store(params = {}, options = {})
      req = build_request(:update_custom_key_store, params)
      req.send_request(options)
    end

    # Updates the description of a customer master key (CMK). To see the
    # description of a CMK, use DescribeKey.
    #
    # You cannot perform this operation on a CMK in a different AWS account.
    #
    # The result of this operation varies with the key state of the CMK. For
    # details, see [How Key State Affects Use of a Customer Master Key][1]
    # in the *AWS Key Management Service Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the customer master key (CMK).
    #
    #   Specify the key ID or the Amazon Resource Name (ARN) of the CMK.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a CMK, use ListKeys or DescribeKey.
    #
    # @option params [required, String] :description
    #   New description for the CMK.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To update the description of a customer master key (CMK)
    #
    #   # The following example updates the description of the specified CMK.
    #
    #   resp = client.update_key_description({
    #     description: "Example description that indicates the intended use of this CMK.", # The updated description.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the CMK whose description you are updating. You can use the key ID or the Amazon Resource Name (ARN) of the CMK.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_key_description({
    #     key_id: "KeyIdType", # required
    #     description: "DescriptionType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateKeyDescription AWS API Documentation
    #
    # @overload update_key_description(params = {})
    # @param [Hash] params ({})
    def update_key_description(params = {}, options = {})
      req = build_request(:update_key_description, params)
      req.send_request(options)
    end

    # @!endgroup

    # @param params ({})
    # @api private
    def build_request(operation_name, params = {})
      handlers = @handlers.for(operation_name)
      context = Seahorse::Client::RequestContext.new(
        operation_name: operation_name,
        operation: config.api.operation(operation_name),
        client: self,
        params: params,
        config: config)
      context[:gem_name] = 'aws-sdk-kms'
      context[:gem_version] = '1.21.0'
      Seahorse::Client::Request.new(handlers, context)
    end

    # @api private
    # @deprecated
    def waiter_names
      []
    end

    class << self

      # @api private
      attr_reader :identifier

      # @api private
      def errors_module
        Errors
      end

    end
  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::KMS
  module Errors

    extend Aws::Errors::DynamicErrors

    class AlreadyExistsException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::AlreadyExistsException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CloudHsmClusterInUseException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CloudHsmClusterInUseException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CloudHsmClusterInvalidConfigurationException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CloudHsmClusterInvalidConfigurationException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CloudHsmClusterNotActiveException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CloudHsmClusterNotActiveException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CloudHsmClusterNotFoundException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CloudHsmClusterNotFoundException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CloudHsmClusterNotRelatedException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CloudHsmClusterNotRelatedException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CustomKeyStoreHasCMKsException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CustomKeyStoreHasCMKsException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CustomKeyStoreInvalidStateException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CustomKeyStoreInvalidStateException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CustomKeyStoreNameInUseException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CustomKeyStoreNameInUseException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class CustomKeyStoreNotFoundException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::CustomKeyStoreNotFoundException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class DependencyTimeoutException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::DependencyTimeoutException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class DisabledException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::DisabledException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class ExpiredImportTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::ExpiredImportTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class IncorrectKeyMaterialException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::IncorrectKeyMaterialException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class IncorrectTrustAnchorException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::IncorrectTrustAnchorException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidAliasNameException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::InvalidAliasNameException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidArnException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::InvalidArnException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidCiphertextException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::InvalidCiphertextException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidGrantIdException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::InvalidGrantIdException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidGrantTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::InvalidGrantTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidImportTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::InvalidImportTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidKeyUsageException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::InvalidKeyUsageException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidMarkerException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::InvalidMarkerException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class KMSInternalException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::KMSInternalException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class KMSInvalidStateException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::KMSInvalidStateException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class KeyUnavailableException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::KeyUnavailableException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class LimitExceededException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::LimitExceededException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class MalformedPolicyDocumentException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::MalformedPolicyDocumentException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class NotFoundException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::NotFoundException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class TagException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::TagException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class UnsupportedOperationException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::KMS::Types::UnsupportedOperationException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::KMS
  class Resource

    # @param options ({})
    # @option options [Client] :client
    def initialize(options = {})
      @client = options[:client] || Client.new(options)
    end

    # @return [Client]
    def client
      @client
    end

  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing for info on making contributions:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

# KG-dev::RubyPacker replaced for aws-sdk-kms/types.rb
# KG-dev::RubyPacker replaced for aws-sdk-kms/client_api.rb
# KG-dev::RubyPacker replaced for aws-sdk-kms/client.rb
# KG-dev::RubyPacker replaced for aws-sdk-kms/errors.rb
# KG-dev::RubyPacker replaced for aws-sdk-kms/resource.rb
# KG-dev::RubyPacker replaced for aws-sdk-kms/customizations.rb

# This module provides support for AWS Key Management Service. This module is available in the
# `aws-sdk-kms` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from AWS Key Management Service all
# extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::KMS::Errors::ServiceError
#       # rescues all service API errors
#     end
#
# See {Errors} for more information.
#
# @service
module Aws::KMS

  GEM_VERSION = '1.21.0'

end

end # Cesium::IonExporter

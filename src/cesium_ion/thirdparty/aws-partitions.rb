require 'set'
require 'json'

module Cesium::IonExporter

module Aws
  module Partitions
    # @api private
    class EndpointProvider

      # Intentionally marked private. The format of the endpoint rules
      # is an implementation detail.
      # @api private
      def initialize(rules)
        @rules = rules
      end

      # @param [String] region
      # @param [String] service The endpoint prefix for the service, e.g. "monitoring" for
      #   cloudwatch.
      # @api private Use the static class methods instead.
      def resolve(region, service)
        "https://" + endpoint_for(region, service)
      end

      # @api private Use the static class methods instead.
      def signing_region(region, service)
        get_partition(region).
          fetch("services", {}).
          fetch(service, {}).
          fetch("endpoints", {}).
          fetch(region, {}).
          fetch("credentialScope", {}).
          fetch("region", region)
      end

      # @api private Use the static class methods instead.
      def dns_suffix_for(region)
        partition = get_partition(region)
        partition['dnsSuffix']
      end

      private

      def endpoint_for(region, service)
        partition = get_partition(region)
        endpoint = default_endpoint(partition, service, region)
        service_cfg = partition.fetch("services", {}).fetch(service, {})

        # Check for service-level default endpoint.
        endpoint = service_cfg.fetch("defaults", {}).fetch("hostname", endpoint)

        # Check for global endpoint.
        if service_cfg["isRegionalized"] == false
          region = service_cfg.fetch("partitionEndpoint", region)
        end

        # Check for service/region level endpoint.
        endpoint = service_cfg.fetch("endpoints", {}).
          fetch(region, {}).fetch("hostname", endpoint)

        endpoint
      end

      def default_endpoint(partition, service, region)
        hostname_template = partition["defaults"]["hostname"]
        hostname_template.
          sub('{region}', region).
          sub('{service}', service).
          sub('{dnsSuffix}', partition["dnsSuffix"])
      end

      def get_partition(region)
        partition_containing_region(region) ||
        partition_matching_region(region) ||
        default_partition
      end

      def partition_containing_region(region)
        @rules['partitions'].find do |p|
          p['regions'].key?(region)
        end
      end

      def partition_matching_region(region)
        @rules['partitions'].find do |p|
          region.match(p["regionRegex"]) ||
          p['services'].values.find { |svc| svc['endpoints'].key?(region) if svc.key? 'endpoints' }
        end
      end

      def default_partition
        @rules['partitions'].find { |p| p["partition"] == "aws" } ||
        @rules['partitions'].first
      end

      class << self

        def resolve(region, service)
          default_provider.resolve(region, service)
        end

        def signing_region(region, service)
          default_provider.signing_region(region, service)
        end

        def dns_suffix_for(region)
          default_provider.dns_suffix_for(region)
        end

        private

        def default_provider
          @default_provider ||= EndpointProvider.new(Partitions.defaults)
        end

      end
    end
  end
end
module Aws
  module Partitions
    class Partition

      # @option options [required, String] :name
      # @option options [required, Hash<String,Region>] :regions
      # @option options [required, Hash<String,Service>] :services
      # @api private
      def initialize(options = {})
        @name = options[:name]
        @regions = options[:regions]
        @services = options[:services]
      end

      # @return [String] The partition name, e.g. "aws", "aws-cn", "aws-us-gov".
      attr_reader :name

      # @param [String] region_name The name of the region, e.g. "us-east-1".
      # @return [Region]
      # @raise [ArgumentError] Raises `ArgumentError` for unknown region name.
      def region(region_name)
        if @regions.key?(region_name)
          @regions[region_name]
        else
          msg = "invalid region name #{region_name.inspect}; valid region "
          msg << "names include %s" % [@regions.keys.join(', ')]
          raise ArgumentError, msg
        end
      end

      # @return [Array<Region>]
      def regions
        @regions.values
      end

      # @param [String] service_name The service module name.
      # @return [Service]
      # @raise [ArgumentError] Raises `ArgumentError` for unknown service name.
      def service(service_name)
        if @services.key?(service_name)
          @services[service_name]
        else
          msg = "invalid service name #{service_name.inspect}; valid service "
          msg << "names include %s" % [@services.keys.join(', ')]
          raise ArgumentError, msg
        end
      end

      # @return [Array<Service>]
      def services
        @services.values
      end

      class << self

        # @api private
        def build(partition)
          Partition.new(
            name: partition['partition'],
            regions: build_regions(partition),
            services: build_services(partition),
          )
        end

        private

        # @param [Hash] partition
        # @return [Hash<String,Region>]
        def build_regions(partition)
          partition['regions'].inject({}) do |regions, (region_name, region)|
            unless region_name == "#{partition['partition']}-global"
              regions[region_name] = Region.build(region_name, region, partition)
            end
            regions
          end
        end

        # @param [Hash] partition
        # @return [Hash<String,Service>]
        def build_services(partition)
          Partitions.service_ids.inject({}) do |services, (svc_name, svc_id)|
            if partition['services'].key?(svc_id)
              svc_data = partition['services'][svc_id]
              services[svc_name] = Service.build(svc_name, svc_data, partition)
            else
              services[svc_name] = Service.build(svc_name, {'endpoints' => {}}, partition)
            end
            services
          end
        end

      end
    end
  end
end
module Aws
  module Partitions
    class PartitionList

      include Enumerable

      def initialize
        @partitions = {}
      end

      # @return [Enumerator<Partition>]
      def each(&block)
        @partitions.each_value(&block)
      end

      # @param [String] partition_name
      # @return [Partition]
      def partition(partition_name)
        if @partitions.key?(partition_name)
          @partitions[partition_name]
        else
          msg = "invalid partition name #{partition_name.inspect}; valid "
          msg << "partition names include %s" % [@partitions.keys.join(', ')]
          raise ArgumentError, msg
        end
      end

      # @return [Array<Partition>]
      def partitions
        @partitions.values
      end

      # @param [Partition] partition
      # @api private
      def add_partition(partition)
        if Partition === partition
          @partitions[partition.name] = partition
        else
          raise ArgumentError, "expected Partition, got #{partition.class}"
        end
      end

      # Removed all partitions.
      # @api private
      def clear
        @partitions = {}
      end

      class << self

        # @api private
        def build(partitions)
          partitions['partitions'].inject(PartitionList.new) do |list, partition|
            list.add_partition(Partition.build(partition))
            list
          end
        end

      end
    end
  end
end

module Aws
  module Partitions
    class Region

      # @option options [required, String] :name
      # @option options [required, String] :description
      # @option options [required, String] :partition_name
      # @option options [required, Set<String>] :services
      # @api private
      def initialize(options = {})
        @name = options[:name]
        @description = options[:description]
        @partition_name = options[:partition_name]
        @services = options[:services]
      end

      # @return [String] The name of this region, e.g. "us-east-1".
      attr_reader :name

      # @return [String] A short description of this region.
      attr_reader :description

      # @return [String] The partition this region exists in, e.g. "aws",
      #   "aws-cn", "aws-us-gov".
      attr_reader :partition_name

      # @return [Set<String>] The list of services available in this region.
      #   Service names are the module names as used by the AWS SDK
      #   for Ruby.
      attr_reader :services

      class << self

        # @api private
        def build(region_name, region, partition)
          Region.new(
            name: region_name,
            description: region['description'],
            partition_name: partition['partition'],
            services: region_services(region_name, partition)
          )
        end

        private

        def region_services(region_name, partition)
          Partitions.service_ids.inject(Set.new) do |services, (svc_name, svc_id)|
            if svc = partition['services'][svc_id]
              services << svc_name if service_in_region?(svc, region_name)
            else
              #raise "missing endpoints for #{svc_name} / #{svc_id}"
            end
            services
          end
        end

        def service_in_region?(svc, region_name)
          svc.key?('endpoints') && svc['endpoints'].key?(region_name)
        end

      end
    end
  end
end

module Aws
  module Partitions
    class Service

      # @option options [required, String] :name
      # @option options [required, String] :partition_name
      # @option options [required, Set<String>] :region_name
      # @option options [required, Boolean] :regionalized
      # @option options [String] :partition_region
      # @api private
      def initialize(options = {})
        @name = options[:name]
        @partition_name = options[:partition_name]
        @regions = options[:regions]
        @regionalized = options[:regionalized]
        @partition_region = options[:partition_region]
      end

      # @return [String] The name of this service. The name is the module
      #   name as used by the AWS SDK for Ruby.
      attr_reader :name

      # @return [String] The partition name, e.g "aws", "aws-cn", "aws-us-gov".
      attr_reader :partition_name

      # @return [Set<String>] The regions this service is available in.
      #   Regions are scoped to the partition.
      attr_reader :regions

      # @return [String,nil] The global patition endpoint for this service.
      #   May be `nil`.
      attr_reader :partition_region

      # Returns `false` if the service operates with a single global
      # endpoint for the current partition, returns `true` if the service
      # is available in mutliple regions.
      #
      # Some services have both a partition endpoint and regional endpoints.
      #
      # @return [Boolean]
      def regionalized?
        @regionalized
      end

      class << self

        # @api private
        def build(service_name, service, partition)
          Service.new(
            name: service_name,
            partition_name: partition['partition'],
            regions: regions(service, partition),
            regionalized: service['isRegionalized'] != false,
            partition_region: partition_region(service)
          )
        end

        private

        def regions(service, partition)
          svc_endpoints = service.key?('endpoints') ? service['endpoints'].keys : []
          names = Set.new(partition['regions'].keys & svc_endpoints)
          names - ["#{partition['partition']}-global"]
        end

        def partition_region(service)
          service['partitionEndpoint']
        end

      end
    end
  end
end
# KG-dev::RubyPacker replaced for aws-partitions/endpoint_provider.rb
# KG-dev::RubyPacker replaced for aws-partitions/partition.rb
# KG-dev::RubyPacker replaced for aws-partitions/partition_list.rb
# KG-dev::RubyPacker replaced for aws-partitions/region.rb
# KG-dev::RubyPacker replaced for aws-partitions/service.rb

module Aws

  # A {Partition} is a group of AWS {Region} and {Service} objects. You
  # can use a partition to determine what services are available in a region,
  # or what regions a service is available in.
  #
  # ## Partitions
  #
  # **AWS accounts are scoped to a single partition**. You can get a partition
  # by name. Valid partition names include:
  #
  # * `"aws"` - Public AWS partition
  # * `"aws-cn"` - AWS China
  # * `"aws-us-gov"` - AWS GovCloud
  #
  # To get a partition by name:
  #
  #     aws = Aws::Partitions.partition('aws')
  #
  # You can also enumerate all partitions:
  #
  #     Aws::Partitions.each do |partition|
  #       puts partition.name
  #     end
  #
  # ## Regions
  #
  # A {Partition} is divided up into one or more regions. For example, the
  # "aws" partition contains, "us-east-1", "us-west-1", etc. You can get
  # a region by name. Calling {Partition#region} will return an instance
  # of {Region}.
  #
  #     region = Aws::Partitions.partition('aws').region('us-west-2')
  #     region.name
  #     #=> "us-west-2"
  #
  # You can also enumerate all regions within a partition:
  #
  #     Aws::Partitions.partition('aws').regions.each do |region|
  #       puts region.name
  #     end
  #
  # Each {Region} object has a name, description and a list of services
  # available to that region:
  #
  #     us_west_2 = Aws::Partitions.partition('aws').region('us-west-2')
  #
  #     us_west_2.name #=> "us-west-2"
  #     us_west_2.description #=> "US West (Oregon)"
  #     us_west_2.partition_name "aws"
  #     us_west_2.services #=> #<Set: {"APIGateway", "AutoScaling", ... }
  #
  # To know if a service is available within a region, you can call `#include?`
  # on the set of service names:
  #
  #     region.services.include?('DynamoDB') #=> true/false
  #
  # The service name should be the service's module name as used by
  # the AWS SDK for Ruby. To find the complete list of supported
  # service names, see {Partition#services}.
  #
  # Its also possible to enumerate every service for every region in
  # every partition.
  #
  #     Aws::Partitions.partitions.each do |partition|
  #       partition.regions.each do |region|
  #         region.services.each do |service_name|
  #           puts "#{partition.name} -> #{region.name} -> #{service_name}"
  #         end
  #       end
  #     end
  #
  # ## Services
  #
  # A {Partition} has a list of services available. You can get a
  # single {Service} by name:
  #
  #     Aws::Partitions.partition('aws').service('DynamoDB')
  #
  # You can also enumerate all services in a partition:
  #
  #     Aws::Partitions.partition('aws').services.each do |service|
  #       puts service.name
  #     end
  #
  # Each {Service} object has a name, and information about regions
  # that service is available in.
  #
  #     service.name #=> "DynamoDB"
  #     service.partition_name #=> "aws"
  #     service.regions #=> #<Set: {"us-east-1", "us-west-1", ... }
  #
  # Some services have multiple regions, and others have a single partition
  # wide region. For example, {Aws::IAM} has a single region in the "aws"
  # partition. The {Service#regionalized?} method indicates when this is
  # the case.
  #
  #     iam = Aws::Partitions.partition('aws').service('IAM')
  #
  #     iam.regionalized? #=> false
  #     service.partition_region #=> "aws-global"
  #
  # Its also possible to enumerate every region for every service in
  # every partition.
  #
  #     Aws::Partitions.partitions.each do |partition|
  #       partition.services.each do |service|
  #         service.regions.each do |region_name|
  #           puts "#{partition.name} -> #{region_name} -> #{service.name}"
  #         end
  #       end
  #     end
  #
  # ## Service Names
  #
  # {Service} names are those used by the the AWS SDK for Ruby. They
  # correspond to the service's module.
  #
  module Partitions

    class << self

      include Enumerable

      # @return [Enumerable<Partition>]
      def each(&block)
        default_partition_list.each(&block)
      end

      # Return the partition with the given name. A partition describes
      # the services and regions available in that partition.
      #
      #     aws = Aws::Partitions.partition('aws')
      #
      #     puts "Regions available in the aws partition:\n"
      #     aws.regions.each do |region|
      #       puts region.name
      #     end
      #
      #     puts "Services available in the aws partition:\n"
      #     aws.services.each do |services|
      #       puts services.name
      #     end
      #
      # @param [String] name The name of the partition to return.
      #   Valid names include "aws", "aws-cn", and "aws-us-gov".
      #
      # @return [Partition]
      #
      # @raise [ArgumentError] Raises an `ArgumentError` if a partition is
      #   not found with the given name. The error message contains a list
      #   of valid partition names.
      def partition(name)
        default_partition_list.partition(name)
      end

      # Returns an array with every partitions. A partition describes
      # the services and regions available in that partition.
      #
      #     Aws::Partitions.partitions.each do |partition|
      #
      #       puts "Regions available in #{partition.name}:\n"
      #       partition.regions.each do |region|
      #         puts region.name
      #       end
      #
      #       puts "Services available in #{partition.name}:\n"
      #       partition.services.each do |service|
      #         puts service.name
      #       end
      #     end
      #
      # @return [Enumerable<Partition>] Returns an enumerable of all
      #   known partitions.
      def partitions
        default_partition_list
      end

      # @param [Hash] new_partitions
      # @api private For internal use only.
      def add(new_partitions)
        new_partitions['partitions'].each do |partition|
          default_partition_list.add_partition(Partition.build(partition))
          defaults['partitions'] << partition
        end
      end

      # @api private For internal use only.
      def clear
        default_partition_list.clear
        defaults['partitions'].clear
      end

      # @return [PartitionList]
      # @api private
      def default_partition_list
        @default_partition_list ||= PartitionList.build(defaults)
      end

      # @return [Hash]
      # @api private
      def defaults
        @defaults ||= begin
          path = File.expand_path('../../partitions.json', __FILE__)
          JSON.load(File.read(path))
        end
      end

      # @return [Hash<String,String>] Returns a map of service module names
      #   to their id as used in the endpoints.json document.
      # @api private For internal use only.
      def service_ids
        @service_ids ||= begin
          # service ids
          {
            'ACM' => 'acm',
            'ACMPCA' => 'acm-pca',
            'APIGateway' => 'apigateway',
            'AlexaForBusiness' => 'a4b',
            'Amplify' => 'amplify',
            'ApiGatewayManagementApi' => 'execute-api',
            'ApiGatewayV2' => 'apigateway',
            'AppMesh' => 'appmesh',
            'AppStream' => 'appstream2',
            'AppSync' => 'appsync',
            'ApplicationAutoScaling' => 'application-autoscaling',
            'ApplicationDiscoveryService' => 'discovery',
            'Athena' => 'athena',
            'AutoScaling' => 'autoscaling',
            'AutoScalingPlans' => 'autoscaling',
            'Backup' => 'backup',
            'Batch' => 'batch',
            'Budgets' => 'budgets',
            'Chime' => 'chime',
            'Cloud9' => 'cloud9',
            'CloudDirectory' => 'clouddirectory',
            'CloudFormation' => 'cloudformation',
            'CloudFront' => 'cloudfront',
            'CloudHSM' => 'cloudhsm',
            'CloudHSMV2' => 'cloudhsmv2',
            'CloudSearch' => 'cloudsearch',
            'CloudTrail' => 'cloudtrail',
            'CloudWatch' => 'monitoring',
            'CloudWatchEvents' => 'events',
            'CloudWatchLogs' => 'logs',
            'CodeBuild' => 'codebuild',
            'CodeCommit' => 'codecommit',
            'CodeDeploy' => 'codedeploy',
            'CodePipeline' => 'codepipeline',
            'CodeStar' => 'codestar',
            'CognitoIdentity' => 'cognito-identity',
            'CognitoIdentityProvider' => 'cognito-idp',
            'CognitoSync' => 'cognito-sync',
            'Comprehend' => 'comprehend',
            'ComprehendMedical' => 'comprehendmedical',
            'ConfigService' => 'config',
            'Connect' => 'connect',
            'CostExplorer' => 'ce',
            'CostandUsageReportService' => 'cur',
            'DAX' => 'dax',
            'DLM' => 'dlm',
            'DataPipeline' => 'datapipeline',
            'DataSync' => 'datasync',
            'DatabaseMigrationService' => 'dms',
            'DeviceFarm' => 'devicefarm',
            'DirectConnect' => 'directconnect',
            'DirectoryService' => 'ds',
            'DocDB' => 'rds',
            'DynamoDB' => 'dynamodb',
            'DynamoDBStreams' => 'streams.dynamodb',
            'EC2' => 'ec2',
            'ECR' => 'api.ecr',
            'ECS' => 'ecs',
            'EFS' => 'elasticfilesystem',
            'EKS' => 'eks',
            'EMR' => 'elasticmapreduce',
            'ElastiCache' => 'elasticache',
            'ElasticBeanstalk' => 'elasticbeanstalk',
            'ElasticLoadBalancing' => 'elasticloadbalancing',
            'ElasticLoadBalancingV2' => 'elasticloadbalancing',
            'ElasticTranscoder' => 'elastictranscoder',
            'ElasticsearchService' => 'es',
            'FMS' => 'fms',
            'FSx' => 'fsx',
            'Firehose' => 'firehose',
            'GameLift' => 'gamelift',
            'Glacier' => 'glacier',
            'GlobalAccelerator' => 'globalaccelerator',
            'Glue' => 'glue',
            'Greengrass' => 'greengrass',
            'GuardDuty' => 'guardduty',
            'Health' => 'health',
            'IAM' => 'iam',
            'ImportExport' => 'importexport',
            'Inspector' => 'inspector',
            'IoT' => 'iot',
            'IoT1ClickDevicesService' => 'devices.iot1click',
            'IoT1ClickProjects' => 'projects.iot1click',
            'IoTAnalytics' => 'iotanalytics',
            'IoTJobsDataPlane' => 'data.jobs.iot',
            'KMS' => 'kms',
            'Kafka' => 'kafka',
            'Kinesis' => 'kinesis',
            'KinesisAnalytics' => 'kinesisanalytics',
            'KinesisAnalyticsV2' => 'kinesisanalytics',
            'KinesisVideo' => 'kinesisvideo',
            'KinesisVideoArchivedMedia' => 'kinesisvideo',
            'KinesisVideoMedia' => 'kinesisvideo',
            'Lambda' => 'lambda',
            'LambdaPreview' => 'lambda',
            'Lex' => 'runtime.lex',
            'LexModelBuildingService' => 'models.lex',
            'LicenseManager' => 'license-manager',
            'Lightsail' => 'lightsail',
            'MQ' => 'mq',
            'MTurk' => 'mturk-requester',
            'MachineLearning' => 'machinelearning',
            'Macie' => 'macie',
            'ManagedBlockchain' => 'managedblockchain',
            'MarketplaceCommerceAnalytics' => 'marketplacecommerceanalytics',
            'MarketplaceEntitlementService' => 'entitlement.marketplace',
            'MarketplaceMetering' => 'metering.marketplace',
            'MediaConnect' => 'mediaconnect',
            'MediaConvert' => 'mediaconvert',
            'MediaLive' => 'medialive',
            'MediaPackage' => 'mediapackage',
            'MediaPackageVod' => 'mediapackage-vod',
            'MediaStore' => 'mediastore',
            'MediaStoreData' => 'data.mediastore',
            'MediaTailor' => 'api.mediatailor',
            'MigrationHub' => 'mgh',
            'Mobile' => 'mobile',
            'Neptune' => 'rds',
            'OpsWorks' => 'opsworks',
            'OpsWorksCM' => 'opsworks-cm',
            'Organizations' => 'organizations',
            'PI' => 'pi',
            'Pinpoint' => 'pinpoint',
            'PinpointEmail' => 'email',
            'PinpointSMSVoice' => 'sms-voice.pinpoint',
            'Polly' => 'polly',
            'Pricing' => 'api.pricing',
            'QuickSight' => 'quicksight',
            'RAM' => 'ram',
            'RDS' => 'rds',
            'RDSDataService' => 'rds-data',
            'Redshift' => 'redshift',
            'Rekognition' => 'rekognition',
            'ResourceGroups' => 'resource-groups',
            'ResourceGroupsTaggingAPI' => 'tagging',
            'RoboMaker' => 'robomaker',
            'Route53' => 'route53',
            'Route53Domains' => 'route53domains',
            'Route53Resolver' => 'route53resolver',
            'S3' => 's3',
            'S3Control' => 's3-control',
            'SES' => 'email',
            'SMS' => 'sms',
            'SNS' => 'sns',
            'SQS' => 'sqs',
            'SSM' => 'ssm',
            'STS' => 'sts',
            'SWF' => 'swf',
            'SageMaker' => 'api.sagemaker',
            'SageMakerRuntime' => 'runtime.sagemaker',
            'SecretsManager' => 'secretsmanager',
            'SecurityHub' => 'securityhub',
            'ServerlessApplicationRepository' => 'serverlessrepo',
            'ServiceCatalog' => 'servicecatalog',
            'ServiceDiscovery' => 'servicediscovery',
            'Shield' => 'shield',
            'Signer' => 'signer',
            'SimpleDB' => 'sdb',
            'Snowball' => 'snowball',
            'States' => 'states',
            'StorageGateway' => 'storagegateway',
            'Support' => 'support',
            'Textract' => 'textract',
            'TranscribeService' => 'transcribe',
            'TranscribeStreamingService' => 'transcribestreaming',
            'Transfer' => 'transfer',
            'Translate' => 'translate',
            'WAF' => 'waf',
            'WAFRegional' => 'waf-regional',
            'WorkDocs' => 'workdocs',
            'WorkLink' => 'worklink',
            'WorkMail' => 'workmail',
            'WorkSpaces' => 'workspaces',
            'XRay' => 'xray',
          }
          # end service ids
        end
      end

    end
  end
end

end # Cesium::IonExporter

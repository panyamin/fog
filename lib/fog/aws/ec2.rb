require 'rubygems'
require 'base64'
require 'cgi'
require 'hmac-sha2'

require File.dirname(__FILE__) + '/ec2/parsers'

module Fog
  module AWS
    class EC2

      # Initialize connection to EC2
      #
      # ==== Notes
      # options parameter must include values for :aws_access_key_id and 
      # :aws_secret_access_key in order to create a connection
      #
      # ==== Examples
      #   sdb = SimpleDB.new(
      #    :aws_access_key_id => your_aws_access_key_id,
      #    :aws_secret_access_key => your_aws_secret_access_key
      #   )
      #
      # ==== Parameters
      # * options<~Hash> - config arguments for connection.  Defaults to {}.
      #
      # ==== Returns
      # * EC2 object with connection to aws.
      def initialize(options={})
        @aws_access_key_id      = options[:aws_access_key_id]
        @aws_secret_access_key  = options[:aws_secret_access_key]
        @hmac       = HMAC::SHA256.new(@aws_secret_access_key)
        @host       = options[:host]      || 'ec2.amazonaws.com'
        @port       = options[:port]      || 443
        @scheme     = options[:scheme]    || 'https'
        @connection = AWS::Connection.new("#{@scheme}://#{@host}:#{@port}")
      end

      # Acquire an elastic IP address.
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :public_ip<~String> - The acquired address
      def allocate_address
        request({
          'Action' => 'AllocateAddress'
        }, Fog::Parsers::AWS::EC2::AllocateAddress.new)
      end

      # Create a new key pair
      #
      # ==== Parameters
      # * key_name<~String> - Unique name for key pair.
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :key_name<~String> - Name of key
      #     * :key_fingerprint<~String> - SHA-1 digest of DER encoded private key
      #     * :key_material<~String> - Unencrypted encoded PEM private key
      #     * :request_id<~String> - Id of request
      def create_key_pair(key_name)
        request({
          'Action' => 'CreateKeyPair',
          'KeyName' => key_name
        }, Fog::Parsers::AWS::EC2::CreateKeyPair.new)
      end

      # Create a new security group
      #
      # ==== Parameters
      # * group_name<~String> - Name of the security group.
      # * group_description<~String> - Description of group.
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :return<~Boolean> - success?
      def create_security_group(name, description)
        request({
          'Action' => 'CreateSecurityGroup',
          'GroupName' => name,
          'GroupDescription' => CGI.escape(description)
        }, Fog::Parsers::AWS::EC2::Basic.new)
      end

      # Create an EBS volume
      #
      # ==== Parameters
      # * availability_zone<~String> - availability zone to create volume in
      # * size<~Integer> - Size in GiBs for volume.  Must be between 1 and 1024.
      # * snapshot_id<~String> - Optional, snapshot to create volume from
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :volume_id<~String> - Reference to volume
      #     * :size<~Integer> - Size in GiBs for volume
      #     * :status<~String> - State of volume
      #     * :create_time<~Time> - Timestamp for creation
      #     * :availability_zone<~String> - Availability zone for volume
      #     * :snapshot_id<~String> - Snapshot volume was created from, if any
      def create_volume(availability_zone, size, snapshot_id = nil)
        request({
          'Action' => 'CreateVolume',
          'AvailabilityZone' => availability_zone,
          'Size' => size,
          'SnapshotId' => snapshot_id
        }, Fog::Parsers::AWS::EC2::CreateVolume.new)
      end

      # Delete a key pair that you own
      #
      # ==== Parameters
      # * key_name<~String> - Name of the key pair.
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :return<~Boolean> - success?
      def delete_key_pair(key_name)
        request({
          'Action' => 'DeleteKeyPair',
          'KeyName' => key_name
        }, Fog::Parsers::AWS::EC2::Basic.new)
      end

      # Delete a security group that you own
      #
      # ==== Parameters
      # * group_name<~String> - Name of the security group.
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :return<~Boolean> - success?
      def delete_security_group(name)
        request({
          'Action' => 'DeleteSecurityGroup',
          'GroupName' => name
        }, Fog::Parsers::AWS::EC2::Basic.new)
      end

      # Delete an EBS volume
      #
      # ==== Parameters
      # * volume_id<~String> - Id of volume to delete.
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :return<~Boolean> - success?
      def delete_volume(volume_id)
        request({
          'Action' => 'DeleteVolume',
          'VolumeId' => volume_id
        }, Fog::Parsers::AWS::EC2::Basic.new)
      end

      # Describe all or specified IP addresses.
      #
      # ==== Parameters
      # * public_ips<~Array> - List of ips to describe, defaults to all
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :request_id<~String> - Id of request
      #     * :address_set<~Array>:
      #       * :instance_id<~String> - instance for ip address
      #       * :public_ip<~String> - ip address for instance
      def describe_addresses(public_ips = [])
        params = indexed_params('PublicIp', public_ips)
        request({
          'Action' => 'DescribeAddresses'
        }.merge!(params), Fog::Parsers::AWS::EC2::DescribeAddresses.new)
      end
      
      # Describe all or specified images.
      #
      # ==== Params
      # * options<~Hash> - Optional params
      #   * :executable_by<~String> - Only return images that the executable_by
      #     user has explicit permission to launch
      #   * :image_id<~Array> - Ids of images to describe
      #   * :owner<~String> - Only return images belonging to owner.
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :request_id<~String> - Id of request
      #     * :image_set<~Array>:
      #       * :architecture<~String> - Architecture of the image
      #       * :image_id<~String> - Id of the image
      #       * :image_location<~String> - Location of the image
      #       * :image_owner_id<~String> - Id of the owner of the image
      #       * :image_state<~String> - State of the image
      #       * :image_type<~String> - Type of the image
      #       * :is_public<~Boolean> - Whether or not the image is public
      def describe_images(options = {})
        params = {}
        if options[:image_id]
          params = indexed_params('ImageId', options[:image_id])
        end
        request({
          'Action' => 'DescribeImages',
          'ExecutableBy' => options[:executable_by],
          'Owner' => options[:owner]
        }.merge!(params), Fog::Parsers::AWS::EC2::DescribeImages.new)
      end
      
      # Describe all or specified instances
      #
      # ==== Parameters
      # * instance_id<~Array> - List of instance ids to describe, defaults to all
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :request_id<~String> - Id of request
      def describe_instances(instance_id = [])
        params = indexed_params('InstanceId', instance_id)
        request({
          'Action' => 'DescribeInstances',
        }.merge!(params), Fog::Parsers::AWS::EC2::DescribeInstances.new)
      end
      
      # Describe all or specified key pairs
      #
      # ==== Parameters
      # * key_name<~Array>:: List of key names to describe, defaults to all
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :request_id<~String> - Id of request
      #     * :key_set<~Array>:
      #       * :key_name<~String> - Name of key
      #       * :key_fingerprint<~String> - Fingerprint of key
      def describe_key_pairs(key_name = [])
        params = indexed_params('KeyName', key_name)
        request({
          'Action' => 'DescribeKeyPairs',
        }.merge!(params), Fog::Parsers::AWS::EC2::DescribeKeyPairs.new)
      end
      
      # Describe all or specified security groups
      #
      # ==== Parameters
      # * group_name<~Array> - List of groups to describe, defaults to all
      #
      # === Returns
      # FIXME: docs
      def describe_security_groups(group_name = [])
        params = indexed_params('GroupName', group_name)
        request({
          'Action' => 'DescribeSecurityGroups',
        }.merge!(params), Fog::Parsers::AWS::EC2::DescribeSecurityGroups.new)
      end
      
      # Describe all or specified volumes.
      #
      # ==== Parameters
      # * volume_ids<~Array> - List of volumes to describe, defaults to all
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :volume_set<~Array>:
      #       * :volume_id<~String> - Reference to volume
      #       * :size<~Integer> - Size in GiBs for volume
      #       * :status<~String> - State of volume
      #       * :create_time<~Time> - Timestamp for creation
      #       * :availability_zone<~String> - Availability zone for volume
      #       * :snapshot_id<~String> - Snapshot volume was created from, if any
      #       * :attachment_set<~Array>:
      #         * :attachment_time<~Time> - Timestamp for attachment
      #         * :device<~String> - How value is exposed to instance
      #         * :instance_id<~String> - Reference to attached instance
      #         * :status<~String> - Attachment state
      #         * :volume_id<~String> - Reference to volume
      def describe_volumes(volume_ids = [])
        params = indexed_params('VolumeId', volume_ids)
        request({
          'Action' => 'DescribeVolumes'
        }.merge!(params), Fog::Parsers::AWS::EC2::DescribeVolumes.new)
      end

      # Release an elastic IP address.
      #
      # ==== Returns
      # * response<~Fog::AWS::Response>:
      #   * body<~Hash>:
      #     * :return<~Boolean> - success?
      def release_address(public_ip)
        request({
          'Action' => 'ReleaseAddress',
          'PublicIp' => public_ip
        }, Fog::Parsers::AWS::EC2::Basic.new)
      end

      # Launch specified instances
      #
      # ==== Parameters
      # * image_id<~String> - Id of machine image to load on instances
      # * min_count<~Integer> - Minimum number of instances to launch. If this
      #   exceeds the count of available instances, no instances will be 
      #   launched.  Must be between 1 and maximum allowed for your account
      #   (by default the maximum for an account is 20)
      # * max_count<~Integer> - Maximum number of instances to launch. If this
      #   exceeds the number of available instances, the largest possible
      #   number of instances above min_count will be launched instead. Must 
      #   be between 1 and maximum allowed for you account
      #   (by default the maximum for an account is 20)
      # * options<~Hash>:
      #   * :availability_zone<~String> - Placement constraint for instances
      #   * :data<~String> -  Additional data to provide to booting instances
      #   * :device_name<~String> - ?
      #   * :encoding<~String> - ?
      #   * :group_id<~String> - Name of security group for instances
      #   * :instance_type<~String> - Type of instance to boot. Valid options
      #     in ['m1.small', 'm1.large', 'm1.xlarge', 'c1.medium', 'c1.xlarge']
      #     default is 'm1.small'
      #   * :kernel_id<~String> - Id of kernel with which to launch
      #   * :key_name<~String> - Name of a keypair to add to booting instances
      #   * :monitoring_enabled<~Boolean> - Enables monitoring, defaults to 
      #     disabled
      #   * :ramdisk_id<~String> - Id of ramdisk with which to launch
      #   * :version<~String> - ?
      #   * :virtual_name<~String> - ?
      #
      # ==== Returns
      def run_instances(image_id, min_count, max_count, options = {})
        request({
          'Action' => 'RunInstances',
          'ImageId' => image_id,
          'MinCount' => min_count,
          'MaxCount' => max_count,
          'AvailabilityZone' => options[:availability_zone],
          'Data' => options[:data],
          'DeviceName' => options[:device_name],
          'Encoding' => options[:encoding],
          'GroupId' => options[:group_id],
          'InstanceType' => options[:instance_type],
          'KernelId' => options[:kernel_id],
          'KeyName' => options[:key_name],
          'Monitoring.Enabled' => options[:monitoring_enabled].nil? ? nil : "#{options[:monitoring_enabled]}",
          'RamdiskId' => options[:ramdisk_id],
          'Version' => options[:version],
          'VirtualName' => options[:virtual_name]
        }, Fog::Parsers::AWS::EC2::Basic.new)
      end

      private

      def indexed_params(name, params)
        indexed, index = {}, 1
        for param in [*params]
          indexed["#{name}.#{index}"] = param
          index += 1
        end
        indexed
      end

      def request(params, parser)
        params.merge!({
          'AWSAccessKeyId' => @aws_access_key_id,
          'SignatureMethod' => 'HmacSHA256',
          'SignatureVersion' => '2',
          'Timestamp' => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
          'Version' => '2009-04-04'
        })

        body = ''
        for key in params.keys.sort
          unless (value = params[key]).nil?
            body << "#{key}=#{CGI.escape(value.to_s).gsub(/\+/, '%20')}&"
          end
        end

        string_to_sign = "POST\n#{@host}\n/\n" << body.chop
        hmac = @hmac.update(string_to_sign)
        body << "Signature=#{CGI.escape(Base64.encode64(hmac.digest).chomp!).gsub(/\+/, '%20')}"

        response = @connection.request({
          :body => body,
          :headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
          :host => @host,
          :method => 'POST',
          :parser => parser
        })

        response
      end

    end
  end
end

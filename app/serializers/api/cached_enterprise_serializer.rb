require 'open_food_network/property_merge'

module Api
  class CachedEnterpriseSerializer < ActiveModel::Serializer
    include SerializerHelper

    cached

    def cache_key
      enterprise.andand.cache_key
    end

    attributes :name, :id, :description, :latitude, :longitude,
               :long_description, :website, :instagram, :linkedin, :twitter,
               :facebook, :is_primary_producer, :is_distributor, :phone, :visible,
               :email_address, :hash, :logo, :promo_image, :path, :pickup, :delivery,
               :icon, :icon_font, :producer_icon_font, :category, :producers, :hubs

    attributes :taxons, :supplied_taxons

    has_one :address, serializer: AddressSerializer

    has_many :supplied_properties, serializer: PropertySerializer
    has_many :distributed_properties, serializer: PropertySerializer

    def pickup
      services = data.shipping_method_services[enterprise.id]
      services ? services[:pickup] : false
    end

    def delivery
      services = data.shipping_method_services[enterprise.id]
      services ? services[:delivery] : false
    end

    def email_address
      enterprise.email_address.to_s.reverse
    end

    def hash
      enterprise.to_param
    end

    def logo
      enterprise.logo(:medium) if enterprise.logo?
    end

    def promo_image
      enterprise.promo_image(:large) if enterprise.promo_image?
    end

    def path
      enterprise_shop_path(enterprise)
    end

    def producers
      relatives = data.relatives[enterprise.id]
      ids_to_objs(relatives.andand[:producers])
    end

    def hubs
      relatives = data.relatives[enterprise.id]
      ids_to_objs(relatives.andand[:distributors])
    end

    def taxons
      if active
        ids_to_objs data.current_distributed_taxons[enterprise.id]
      else
        ids_to_objs data.all_distributed_taxons[enterprise.id]
      end
    end

    def supplied_taxons
      ids_to_objs data.supplied_taxons[enterprise.id]
    end

    def supplied_properties
      (product_properties + producer_properties).uniq do |property_object|
        property_object.property.presentation
      end
    end

    # This results in 3 queries per enterprise
    def distributed_properties
      if active
        product_properties = Spree::Property.currently_sold_by(enterprise)
        producer_property_ids = ProducerProperty.currently_sold_by(enterprise).pluck(:property_id)
      else
        product_properties = Spree::Property.ever_sold_by(enterprise)
        producer_property_ids = ProducerProperty.ever_sold_by(enterprise).pluck(:property_id)
      end

      producer_properties = Spree::Property.where(id: producer_property_ids)

      (product_properties + producer_properties).uniq do |property_object|
        property_object.property.presentation
      end
    end

    def active
      data.active_distributors.andand.include? enterprise
    end

    # Map svg icons.
    def icon
      icons = {
        hub: "/assets/map_005-hub.svg",
        hub_profile: "/assets/map_006-hub-profile.svg",
        producer_hub: "/assets/map_005-hub.svg",
        producer_shop: "/assets/map_003-producer-shop.svg",
        producer: "/assets/map_001-producer-only.svg",
      }
      icons[enterprise.category]
    end

    # Choose regular icon font for enterprises.
    def icon_font
      icon_fonts = {
        hub: "ofn-i_063-hub",
        hub_profile: "ofn-i_064-hub-reversed",
        producer_hub: "ofn-i_063-hub",
        producer_shop: "ofn-i_059-producer",
        producer: "ofn-i_059-producer",
      }
      icon_fonts[enterprise.category]
    end

    # Choose producer page icon font - yes, sadly its got to be different.
    # This duplicates some code but covers the producer page edge case where
    # producer-hub has a producer icon without needing to duplicate the category logic in angular.
    def producer_icon_font
      icon_fonts = {
        hub: "",
        hub_profile: "",
        producer_hub: "ofn-i_059-producer",
        producer_shop: "ofn-i_059-producer",
        producer: "ofn-i_059-producer",
      }
      icon_fonts[enterprise.category]
    end

    private

    def product_properties
      enterprise.supplied_products.flat_map(&:properties)
    end

    def producer_properties
      enterprise.properties
    end

    def enterprise
      object
    end

    def data
      options[:data]
    end
  end
end

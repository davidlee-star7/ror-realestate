if params[:to].to_s.downcase == 'myastoria'
  xml << render(partial: 'listing_for_myastoria', locals: {listing: listing})
elsif params[:to].to_s.downcase == 'zumper'
  xml << render(partial: 'listing_for_zumper', locals: {listing: listing})
else
  xml.property(id: listing.id, type: listing.listing_type.try(:name).downcase,
               status: status_for_export(listing.status.try(:name)),
               url: (params[:type].to_s.downcase == 'sale' ? 'http://horowitzrealestate.com/category/listings/sales/' : 'http://horowitzrealestate.com/category/listings/rentals/')) do
    xml.location do
      if params[:to].to_s.downcase == 'nakedapartments'
        xml.address listing.street_address
        xml.apartment listing.unit_no
        xml.city listing.neighborhood.try(:name)
      else
        if listing.fake_address.blank?
          xml.address listing.street_address
        else
          xml.address listing.fake_address
        end

        if listing.fake_unit_no.blank?
          xml.apartment listing.unit_no
        else
          xml.apartment listing.fake_unit_no
        end

        if listing.fake_city_id.blank?
          xml.city listing.neighborhood.try(:name)
        else
          xml.city listing.fake_city.try(:name)
        end
      end
      # todo: required!
      xml.state 'NY'
      xml.zipcode listing.zip_code

      # xml.neighborhood listing.neighborhood.try(:name)
    end

    xml.details do
      xml.price listing.price.to_i
      # <noFee/> <!-- include if no fee -->
      # <maintenance/> <!-- monthly (Also Common Charges for condos) -->
      # <exclusive> If this is an exclusive listing include this tag. If it is not exclusive then leave this tag out.
      if (params[:to].to_s.downcase != 'nakedapartments') or
          ((params[:to].to_s.downcase == 'nakedapartments') and !listing.hide_address_for_nakedapartments?)
        xml.exclusive
      end

      if (params[:to].to_s.downcase == 'nakedapartments') and listing.featured?
        xml.featured
      end

      # <taxes/> <!-- monthly -->
      xml.bedrooms bed_for_export(listing.bed.name)
      xml.bathrooms listing.full_baths_no
      xml.half_baths listing.half_baths_no
      # todo: required!
      xml.totalrooms bed_for_export(listing.bed.name) + listing.full_baths_no.to_i + listing.half_baths_no.to_i

      xml.squareFeet listing.size
      # <lotarea> Area of the lot in whole or partial acres, examples: '3', '0.85'
      # <lotsize></lotsize> Dimensions of the lot as length and width in linear feet, examples: '20x40', '60x90'

      xml.availableOn listing.available_date
      # <listedon></listedon> If this property is already on the market this should be the date it was first listed. Example: 2006-09-21
      # <soldon></soldon> If this property is sold, this should be the date that it sold on. Example: 2006-05-22

      # Description of the property. Should not contain any HTML or XML tags. Any special characters should be escaped, Please use CDATA if listing descriptions include line breaks.
      # todo: check for line breaks
      xml.description do
        if listing.description.to_s.include? "\n"
          xml.cdata! listing.description.to_s.sub("\n", '<br />').html_safe
        else
          xml.text! listing.description.to_s
        end
      end

      xml.propertyType property_type_for_export(listing.property_type.name)
      # <mlsid></mlsid> The id number in the associated MLS
      # <mlsname></mlsname> The name of the MLS that this listing is listed in.
      # <built></built> Date or year the property was originally built

      xml.amenities do
        # <doorman></doorman>
        # <prewar></prewar>
        # <gym></gym>
        # <pool></pool>

        if listing.elevator?
          xml.elevator
        end
        # <garage></garage>
        if listing.parking_available?
          xml.parking
        end
        if listing.balcony?
          xml.balcony
        end
        if listing.storage_available?
          xml.storage
        end
        if listing.patio?
          xml.patio
        end
        # <fireplace></fireplace>
        # <washerdryer></washerdryer>
        # <furnished></furnished>

        if listing.cats? or listing.dogs? or listing.approved_pets_only?
          xml.pets
        end

        if listing.dishwasher?
          xml.dishwasher
        end

        others = []
        others.push('backyard') if listing.backyard?
        others.push('laundry in building') if listing.laundry_in_building?
        others.push('laundry in unit') if listing.laundry_in_unit?
        others.push('live-in super') if listing.live_in_super?
        others.push('absentee landlord') if listing.absentee_landlord?
        others.push('walk up') if listing.walk_up?
        others.push('yard') if listing.yard?

        others.push('heat and hot water') if listing.heat_and_hot_water?
        others.push('gas') if listing.gas?
        others.push('all') if listing.all_utilities?
        others.push('none') if listing.none?

        other = others.join ', '

        unless other.blank?
          xml.other other
        end
      end
    end

    xml.agents do
      if (params[:to].to_s.downcase == 'nakedapartments') and listing.user.present? and !listing.user.naked_apartments_account?
        agent = User.where(name: 'Peter Horowitz').first
        if agent.nil?
          agent = User.where(naked_apartments_account: true).first
          agent = User.first if agent.nil?
        end
      else
        agent = listing.user
      end
      unless agent.nil?
        xml.agent(id: agent.id) do
          xml.name agent.name
          # <company>	optional	Name of the company this agent works for, example: Eastside Realty
          xml.photo agent.avatar_url

          # todo: Required!
          xml.email agent.email
          xml.phone_numbers do
            xml.office agent.phone
            xml.fax agent.fax
          end
        end
      end
    end

    xml.media do
      listing.property_photos.each do |photo|
        xml.photo(url: photo.photo_url_url) if photo.photo_url_url.present?
      end
      listing.property_floorplans.each do |floorplan|
        xml.floorplan(url: floorplan.floorplan_url_url) if floorplan.floorplan_url_url.present?
      end
      listing.property_videos.each do |video|
        xml.video(url: video.video_url) if video.video_url.present?
      end
    end
  end
end

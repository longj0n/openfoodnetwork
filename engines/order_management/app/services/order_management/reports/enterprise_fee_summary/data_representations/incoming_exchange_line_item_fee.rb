# frozen_string_literal: true

# This module provides EnterpriseFeeSummary::Scope DB result to report mappings for incoming
# exchange fees that use line item -based calculators.

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      module DataRepresentations
        class IncomingExchangeLineItemFee
          include UsingEnterpriseFee

          def fee_calculated_on_transfer_through_name
            data["incoming_exchange_enterprise_name"]
          end

          def tax_category_name
            data["tax_category_name"] || data["product_tax_category_name"]
          end
        end
      end
    end
  end
end

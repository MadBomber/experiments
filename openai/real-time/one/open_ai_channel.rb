# app/channels/open_ai_channel.rb
class OpenAiChannel < ApplicationCable::Channel
  def subscribed
    puts "Subscribed to open_ai_#{current_user.id}"
    stream_from "open_ai_#{current_user.id}"
    @openai_client = OpenAiWebsocket.new(current_user.id)
    @openai_client.connect
    @openai_client.session_update(event_id: SecureRandom.uuid)
    item = {
            "id": "msg_001",
            "type": "message",
            "status": "completed",
            "role": "user",
            "content": [
                {
                    "type": "input_text",
                    "text": "You are a representative of Little Bird Electronics.You are on a phone call with a customer from at Little Bird Electronics. IMPORTANT: Keep responses SHORT and curt and polite!!! #{background_info}"
                }
            ]
        }
    @openai_client.conversation_item_create(item: item, event_id: SecureRandom.uuid)
    # @openai_client.create_response(event_id: "12345")
  end

  def background_info
    text = <<~TEXT
      Little Bird Electronics is an Australian electronics retailer.
      We specialize in Arduino, Raspberry Pi, and other maker electronics.
      Our store is located in Sydney, but we ship Australia-wide.
      We offer a wide range of products including sensors, motors, displays, and development boards.
      Our knowledgeable staff can assist with project ideas and technical questions.
      We also run workshops and events for the maker community.

      Question: How can educational institutions and government agencies place purchase orders?
      Answer: Email your purchase order or the list of products you wish to purchase to team@littlebird.com.au.
      Alternatively, place your order online and select the “Purchase Order” option at checkout.
      Question: What payment terms do you offer for educational institutions and government agencies?
      Answer: We offer net payment terms, allowing payment within 30 calendar days from the invoice date.
      Question: How long does it take to process purchase orders?
      Answer: We usually process purchase orders on the same NSW business day, though it might take a bit longer sometimes.
      Question: Where can I find your business details, such as ABN and bank information?
      Answer: Our key business details, including ABN and bank details, are provided below or can be sent upon request.
      Question: How can private businesses place purchase orders?
      Answer: Private businesses can place orders through our website.
      If payment terms are needed, apply before submitting a purchase order.
      Once approved, follow the same process as educational institutions.
      Question: Do private businesses need to apply for payment terms before submitting a purchase order?
      Answer: Yes, private businesses must apply for payment terms prior to submitting a purchase order.
      Question: How can I request a quote for bulk orders or for procedural reasons?
      Answer: Email us at help@littlebird.com.au with the SKU and quantity for each product.
      Include your delivery address and accounts payable information.
      Question: Where can I find the SKU for each product?
      Answer: The SKU is located on the product’s page, just beneath the product title.
      Question: Can I download a copy of my shopping cart?
      Answer: Yes, use the “Download Cart as CSV” button on the cart page.
      Question: Who is eligible for education orders?
      Answer: Public and private schools registered in Australia.
      Australian public and private universities.
      Government-accredited colleges catering to vocational and tertiary education sectors.
      Question: What special pricing do you offer for educational institutions?
      Answer: Special pricing structures for bulk purchases.
      Everyday competitive pricing due to our internet-first business model.
      Question: What is the ordering process for educational institutions?
      Answer: Selection: Browse and select products.
      Request a Quote or Place an Order: Before sending a purchase order, teachers should request a quote or place an order online.
      Prepare Purchase Order: Create a school purchase order or “school order” document with all relevant details.
      Email Order: Send the purchase order to team@littlebird.com.au.
      Confirmation & Processing: Receive order acknowledgment and estimated delivery date.
      Payment & Dispatch: Follow payment instructions; once payment is confirmed, the order will be dispatched.
      Question: Do you offer customization options for education orders?
      Answer: Yes, options include tailored kits and bundles, product modifications, branding and labeling, and special packaging.
      Question: How can I request customization for my order?
      Answer: Indicate your interest in customization when placing an order or requesting a quote.
      Our team will contact you to discuss specific needs.
      Question: What are your payment terms for education orders?
      Answer: Payment is due within 30 calendar days from the invoice date.
      These terms are firm and non-negotiable.
      Question: What payment methods are accepted?
      Answer: Various payment methods are accepted; details are provided on the invoice.
      Question: How do you handle shipping and delivery for education orders?
      Answer: Carrier Partner: Australia Post.
      Signature on Delivery: Required for all orders.
      Arrangements During School Holidays: Deliveries can be scheduled to avoid school closures.
      Tracking: A tracking number is provided once the order is dispatched.
      Question: What is your returns and warranty policy for education orders?
      Answer: No Returns for Change of Mind: Returns are not accepted for unused products or change of mind.
      Faulty Products: Returns are accepted for products with genuine faults.
      Consumables: Excluded from returns and warranty policy.
      Initiating a Return: Contact us with order details and a description of the issue.
      Question: What support and resources do you offer for education orders?
      Answer: Dedicated Support Team: Available to address queries and technical issues.
      Online Resources: User manuals, how-to guides, tutorial videos, and FAQs.
      Training and Workshops: Offered periodically.
      Community Engagement: Opportunities to collaborate with other educators.
      Question: How can I contact Little Bird Electronics?
      Answer: Phone: 1300 240 817
      Email: team@littlebird.com.au
      Physical Address: Unit 13, 8-12 Leighton Place, Hornsby, NSW 2077, Australia
      Mailing Address: PO Box 5036, South Turramurra, NSW 2074, Australia
      Question: What are your key business details?
      Answer: Business Name: Little Bird Electronics Pty Ltd
      ABN: 15 634 521 449
      ACN: 634 521 449
      Bank Details:
      Account Name: Little Bird Electronics
      Bank: ANZ
      BSB: 012306
      Account Number: 316319624
      Swift Code: ANZBAU3M
      Question: Who should I contact for accounts and remittance inquiries?
      Answer: Contact Person: Madeleine Schappi
      Email: team@littlebird.com.au
      Phone: 1300 240 817
      Question: What are your Supplier IDs for educational departments?
      Answer: NSW DET Vendor ID: 100135487
      QLD OneSchool Supplier Number: S20017189
      SA Dept. of Education Supplier ID: LBE2077
      Question: Do you have insurance coverage details available?
      Answer: Yes, we have Workers Compensation, Public Liability, Product Liability, and Professional Indemnity insurance. Certificates of Currency can be provided upon request.
      Question: What should I do if I need assistance during the ordering process?
      Answer: Contact our dedicated team at team@littlebird.com.au or call 1300 240 817 for support.
      Question: Can I arrange special packaging or branding for bulk educational orders?
      Answer: Yes, we offer branding and special packaging options for bulk orders. Please discuss your requirements with our team.
      Question: How can I track the status of my order?
      Answer: A tracking number will be emailed to you once your order has been dispatched, allowing you to monitor delivery progress.
      Question: Are there any resources to help integrate your products into our curriculum?
      Answer: Yes, we offer online resources and can provide training or workshops to help educators effectively use our products.
      Question: What is the procedure if I receive a faulty product?
      Answer: Contact us immediately with your order number and details of the fault. We will guide you through the return and replacement process.
      Question: Do you offer discounts for bulk purchases?
      Answer: Yes, we offer special pricing structures for bulk orders by educational institutions.
      Question: Is it possible to get an official quote for procurement purposes?
      Answer: Absolutely, email us the SKUs and quantities needed along with your delivery and accounts payable information to receive an official quote.
      Question: Do you require verification for educational institution orders?
      Answer: Verification may be required. An official representative must complete the ordering process, and relevant documentation may be requested.
      Question: Can I arrange for my order to be delivered after a specific date?
      Answer: Yes, please inform us of any delivery scheduling needs, and we will accommodate them accordingly.
      Question: Are there any exclusions to your returns policy?
      Answer: Yes, consumable items are excluded, and we do not accept returns for change of mind or unused products.
      Question: How often do you update your product offerings?
      Answer: We regularly update our product range and will keep you informed about new releases and enhancements.
      Question: What is the best way to stay informed about your latest products and offers?
      Answer: Join our mailing list or follow us on social media for updates on products, offers, and educational resources.
      Question: Do you provide support after the purchase?
      Answer: Yes, our support doesn’t end after the sale. We’re here to assist with any questions or issues you may have with our products.
      Question: Can I get a copy of your Certificates of Currency for insurance purposes?
      Answer: Yes, we can provide Certificates of Currency for our insurance policies upon request.
      Question: What are your office hours?
      Answer: Our office hours are standard NSW business hours. Please contact us for specific times.
      Question: Do you have a fax number?
      Answer: Yes, our fax number is (02) 8319 2017.
      Question: Can I apply for payment terms as a private business?
      Answer: Yes, private businesses can apply for payment terms, but approval is required before submitting a purchase order.
      Question: Do you offer international shipping?
      Answer: The provided information focuses on Australian educational institutions. Please contact us directly to inquire about international shipping options.
      Question: What is your policy on product warranties?
      Answer: Warranty durations vary by product. Specific warranty information is provided with the product or upon request.
      Question: How do I become part of your educator community?
      Answer: Reach out to us at team@littlebird.com.au to learn more about joining our community of educators.
      Question: Are there any special considerations for orders during public holidays?
      Answer: Yes, processing and delivery times may be affected during public holidays. Please contact us to make any necessary arrangements.
      Question: Do you provide invoicing options compatible with our procurement systems?
      Answer: Yes, we can accommodate various invoicing requirements. Please provide us with the necessary specifications.
      Question: How can I ensure my institution gets the best possible pricing?
      Answer: For bulk orders or special pricing inquiries, contact our sales team to discuss available discounts and offers.
      Question: Is technical support available for your products?
      Answer: Yes, technical support is available through our dedicated support team and online resources.
      Question: What steps do you take to ensure product quality?
      Answer: We adhere to strict quality control measures and partner with reputable manufacturers to ensure high-quality products.
      Question: Can I schedule a demonstration of your products?
      Answer: Please contact us to discuss the possibility of product demonstrations or presentations for your institution.

    TEXT

    text
  end

  def unsubscribed
    @openai_client.close if @openai_client
  end

  def append_audio(data)
    @openai_client.append_audio(data["audio"])
  end

  def close_session
    @openai_client.close
  end

  def restart_session
    @openai_client = OpenAiWebsocket.new(current_user.id)
    @openai_client.connect
  end

  def cancel_response
    @openai_client.cancel_response
  end

  def receive(data)
    case data["type"]
    when "audio"
      @openai_client.input_audio_buffer_append(data["audio"])
    when "text"
      @openai_client.add_message(data["text"])
    end
  end
end

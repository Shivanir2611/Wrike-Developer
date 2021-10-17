public class G2CrowdEmailHandler implements Messaging.InboundEmailHandler {

    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail inboundEmail,
                                                           Messaging.InboundEnvelope envelope) {
        final Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try {
            processEmail(inboundEmail.htmlBody);
            result.success = true;
        } catch (Exception e) {
            sendErrorNotificationEmail('Email processing failed.', e, inboundEmail.htmlBody);
            result.success = false;
        }
        return result;
    }

    private void processEmail(final String emailText) {
        final Map<String, String> values = parseEmail(emailText);
        if (values.isEmpty()) {
            throw new EmailHandlerException('Email parsing failed.');
        }
        final Lead leadFromEmail = createLead(values);
        final Lead existingLead = findLeadByEmail(leadFromEmail.Email);

        final Lead lead = existingLead != null ? getUpdatedLead(leadFromEmail, existingLead) : leadFromEmail;
        if (lead.Id != null) {
            update lead;
        } else {
            insert lead;
        }

        final String campaignName = 'HT-GM-LLP-G2 Leads-2019Q4';
        final Campaign campaign = findCampaignByName(campaignName);
        if (campaign == null) {
            throw new EmailHandlerException('Campaign "' + campaignName + '" is not found.');
        }
        if (findCampaignMember(lead.Id, campaign.Id) == null) {
            insert new CampaignMember(
                    CampaignId = campaign.Id,
                    LeadId = lead.Id
            );
        }

        final String marketingNotes =
                StringUtils.defaultIfBlank(values.get('Action taken by User to Initiate Lead'), '') + ' ' +
                StringUtils.defaultIfBlank(values.get('Message'), '');
        if (String.isNotBlank(marketingNotes)) {
            insert new Note(
                    ParentId = lead.Id,
                    Title = 'Marketing Notes',
                    Body = marketingNotes
            );
        }
    }

    private Lead createLead(final Map<String, String> values) {
        final String email = getLinkText(values.get('Business Email'));
        if (!EmailUtil.isValidEmail(email)) {
            throw new EmailHandlerException('Email is not valid ' + email);
        }

        final String companyName = getLinkText(values.get('Company'));
        final Lead lead = new Lead(
                FirstName = StringUtils.defaultIfBlank(values.get('First Name'), '-'),
                LastName = StringUtils.defaultIfBlank(values.get('Last Name'), '-'),
                Email = email,
                Phone = values.get('Phone Number'),
                Company = StringUtils.defaultIfBlank(companyName, 'Unknown <' + email + '>'),
                Website = companyName,
                Self_Selected_Employee_Size__c = values.get('Company Size'),
                Industry = values.get('Industry'),
                LeadSource = 'Partner',
                Lead_Sub_Source__c = 'G2Crowd',
                OwnerId = WrikeConstants.GLQ_ID,
                Status = 'Open'
        );
        final String countryCode = values.get('Remote Ip Country Iso Code');
        final String stateCode = values.get('Remote Ip State Iso Code');

        if (CountryUtil.isValidCountryCode(countryCode)) {
            lead.CountryCode = countryCode;
            if (CountryUtil.isValidCanadaUsState(countryCode, stateCode)) {
                lead.StateCode = stateCode;
            }
            lead.City = values.get('Remote Ip City Name');
        }
        return lead;
    }

    private Lead getUpdatedLead(final Lead leadFromEmail, final Lead existingLead) {
        if (existingLead.OwnerId == WrikeConstants.RLQ_ID) {
            existingLead.OwnerId = WrikeConstants.GLQ_ID;
            existingLead.Status = 'Open';
        }
        if (existingLead.Phone == null) {
            existingLead.Phone = leadFromEmail.Phone;
        }
        if (existingLead.Website == null) {
            existingLead.Website = leadFromEmail.Website;
        }
        if (existingLead.Self_Selected_Employee_Size__c == null) {
            existingLead.Self_Selected_Employee_Size__c = leadFromEmail.Self_Selected_Employee_Size__c;
        }
        if (existingLead.Industry == null) {
            existingLead.Industry = leadFromEmail.Industry;
        }
        final Boolean needAddressUpdate = (leadFromEmail.CountryCode != null && existingLead.CountryCode == null)
                || (leadFromEmail.CountryCode == existingLead.CountryCode
                        && leadFromEmail.StateCode != null && existingLead.StateCode == null)
                || (leadFromEmail.CountryCode == existingLead.CountryCode
                        && leadFromEmail.StateCode == existingLead.StateCode
                        && leadFromEmail.City != null && existingLead.City == null);
        if (needAddressUpdate) {
            existingLead.CountryCode = leadFromEmail.CountryCode;
            existingLead.StateCode = leadFromEmail.StateCode;
            existingLead.City = leadFromEmail.City;
        }
        return existingLead;
    }

    private Map<String, String> parseEmail(final String emailText) {
        final Map<String, String> values = new Map<String, String>();
        final String dataText = emailText.substringBetween('Full Name:', 'Feel free to follow up')
                .replaceAll('=\n', '')
                .replaceAll('\n', '')
                .replaceAll(' class=""', '')
                .replaceAll('<br/>', '<br>');
        if (String.isNotBlank(dataText)) {
            final Pattern linePattern = Pattern.compile('([^:]+?): (.+?)$');
            final String[] lines = ('Full Name:' + dataText).split('<br>');
            for (String line : lines) {
                final Matcher lineMatcher = linePattern.matcher(line);
                if (lineMatcher.find()) {
                    final String value = lineMatcher.group(2);
                    if (value != null) {
                        values.put(lineMatcher.group(1).trim().replace('<p>', ''),
                                value.trim().replace('</p>', '').unescapeHtml4());
                    }
                }
            }
        }
        return values;
    }

    private void sendErrorNotificationEmail(final String subject, final Exception e, final String emailBody) {
        final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String> { UserInfo.getUserEmail() });
        mail.setSubject(subject);
        mail.setPlainTextBody(e.getMessage() + '\n' + e.getStackTraceString() + '\n' + emailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    private String getLinkText(final String data) {
        if (data == null) {
            return null;
        }
        final Matcher matcher = Pattern.compile('^<a[^>]*>(.*)</a>').matcher(data);
        return matcher.find() ? matcher.group(1) : data;
    }

    private Lead findLeadByEmail(final String email) {
        final List<Lead> leads = [
                SELECT Id, OwnerId, LeadSource, FirstName, LastName, Email, Phone, Company, Website, Status,
                        Self_Selected_Employee_Size__c, Industry, CountryCode, StateCode, City, Lead_Sub_Source__c
                FROM Lead
                WHERE Email = :email AND IsConverted = false
                ORDER BY CreatedDate DESC
        ];
        if (leads.isEmpty()) {
            return null;
        }
        for (Lead lead : leads) {
            if (lead.OwnerId != WrikeConstants.RLQ_ID) {
                return lead;
            }
        }
        return leads.get(0);
    }

    private Campaign findCampaignByName(final String name) {
        final List<Campaign> campaigns = [
                SELECT Id
                FROM Campaign
                WHERE Name = :name
        ];
        return campaigns.isEmpty() ? null : campaigns.get(0);
    }

    private CampaignMember findCampaignMember(final Id leadId, final Id campaignId) {
        final List<CampaignMember> campaignMembers = [
                SELECT Id
                FROM CampaignMember
                WHERE LeadId = :leadId
                AND CampaignId = :campaignId
        ];
        return campaignMembers.isEmpty() ? null : campaignMembers.get(0);
    }

    public class EmailHandlerException extends Exception {
    }
}
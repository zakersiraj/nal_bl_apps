# frozen_string_literal: true
class CatalogController < ApplicationController

  include Blacklight::Catalog
  include Blacklight::Marc::Catalog


  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      :qt => 'search',
      :fl => 'id,author,author_primary,source,subject,journal,abstract,agid,pmid,pmcid,chorus,publication_year,
              fulltext,url,title,language,volume,issue,issn,startpage,endpage,doi,pageoffset,
              date,timestamp,text_availability,page,pmid_url,pmcid_url,chorus_url,doi_url,dataset,
              format,handle,handle_url,type,publication_year_rev,files_ss',
      :'hl.simple.pre' => '<b>',
      :'hl.simple.post' => '</b>',
      :'hl.snippets' =>3,
      :'f.abstract.hl.fragsize' => 80,
      :'hl.boundaryScanner' => 'simple' ,
      :"hl.fl" => 'title author source subject abstract journal sourec mesh_ss',
      :"f.author.hl.alternateField" => 'author',
      :"f.source.hl.alternateField" => 'source',
      :"f.subject.hl.alternateField" => 'subject',
      #{}:"f.agid.hl.alternateField" => 'agid',
      :"f.abstract.hl.alternateField" => 'abstract',
      :"f.abstract.hl.maxAlternateFieldLength" => 400,
      :"hl.usePhraseHighlighter" => true,
      :hl => true,
      rows: 10
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
      qt: 'search',
      fl: config.default_solr_params[:fl],
      q: '{!term f=id v=$id}'
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title'
    config.index.display_type_field = 'format'

    # solr field configuration for document/show views
    config.show.title_field = 'title'
    config.show.display_type_field = 'format'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)
    #config.add_facet_field 'text_availability', :label => 'Text Availability',solr_params: { 'facet.mincount' => 1 }
    config.add_facet_field 'text_availability', label: 'Text Availability', :query => {
      :pubag_full_txt => {label: 'PubAg Full Text', fq: '+aris:*'},
      :full_text => { label: 'Full Text', fq: "-aris:* +format:fulltext"},
      :citation => { label: 'Citation Only', fq: "-aris:* +format:citation"}
      #:unkown => {label: 'Unknown', fq: '-aris:* -format:fulltext -format:citation'}
    }

    config.add_facet_field 'datasets', label: 'Associated Data', :query => {
      :datasets => { label: 'Dataset Available', fq: "dataset_availability:['' TO *]" }
    }

    config.add_facet_field 'journal_name', :label => 'Journal', :limit => 5 ,solr_params: { 'facet.mincount' => 1 }
    config.add_facet_field 'subject_term', :label => 'Subject', :limit => 5, solr_params: { 'facet.mincount' => 1 }
    config.add_facet_field 'subject_category', :label => 'General Topic', :limit => 5, solr_params: { 'facet.mincount' => 1 }


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'author', :label => 'Author', :highlight => true
    #config.add_index_field 'journal', :label => 'Source', helper_method: 'journal_helper'
    config.add_index_field 'issn', :label => 'ISSN'
    config.add_index_field 'subject', :label => 'Subject',:highlight => true
    config.add_index_field 'abstract', :label => 'Abstract', :highlight => true
    #config.add_index_field 'format', :label => 'Availability',helper_method: 'integration_links',data_map: config.full_text_fields
    #config.add_index_field 'dataset', :label => 'Datasets', helper_method: 'datasets'
    #config.add_index_field 'agid', :label => 'Identifiers', helper_method: 'integration_links',data_map: config.integration_fields # :highlight => true
    #config.add_index_field 'handle', :label => "Handle" #I18n.t("blacklight.integration_labels.handle")
    #config.add_index_field 'doi', :label => I18n.t("blacklight.integration_labels.doi"), helper_method: 'link_me'
    #config.add_index_field 'pmid', :label => I18n.t("blacklight.integration_labels.pmid"), helper_method: 'link_me'
    #config.add_index_field 'pmcid', :label => I18n.t("blacklight.integration_labels.pmcid"), helper_method: 'link_me'
    #config.add_index_field 'chorus', :label => I18n.t("blacklight.integration_labels.chorus"), helper_method: 'link_me'


    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'author', :label => 'Author'
    config.add_show_field 'journal', :label => 'Source'
    config.add_show_field 'issn', :label => 'ISSN'
    config.add_show_field 'subject', :label => 'Subject'#, helper_method: 'fielded_search'
    config.add_show_field 'abstract', :label => 'Abstract'
    #config.add_show_field 'format', :label => 'Availability',helper_method: 'integration_links',data_map: config.full_text_fields
    #config.add_show_field 'dataset', :label => 'Datasets', helper_method: 'datasets'
    #config.add_show_field 'agid', :label => "Identifiers", helper_method: 'integration_links',data_map: config.integration_fields
    #config.add_show_field 'handle', :label => "Handle"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        qf: '$title_qf',
        pf: '$title_pf'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = {
        qf: '$author_qf',
        pf: '$author_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = {
        qf: '$subject_qf',
        pf: '$subject_pf'
      }
    end

    config.add_search_field('journal') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'journal' }
      field.solr_local_parameters = {
        :qf => 'journal',
        :pf => 'journal'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'relevance', :sort => 'score desc, date desc, title_sort asc', :label => 'relevance'
    config.add_sort_field 'date-desc', :sort => 'date desc, title_sort asc', :label => 'newest'
    config.add_sort_field 'date-asc', :sort => 'date asc, title_sort asc', :label => 'oldest'
    config.add_sort_field 'title', :sort => 'title_sort asc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
  end
end

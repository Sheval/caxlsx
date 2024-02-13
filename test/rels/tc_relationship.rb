# frozen_string_literal: true

require 'tc_helper'

class TestRelationships < Minitest::Test
  def test_instances_with_different_attributes_have_unique_ids
    rel_1 = Axlsx::Relationship.new(Object.new, Axlsx::WORKSHEET_R, 'target')
    rel_2 = Axlsx::Relationship.new(Object.new, Axlsx::COMMENT_R, 'foobar')

    refute_equal rel_1.Id, rel_2.Id
  end

  def test_instances_with_same_attributes_share_id
    source_obj = Object.new
    instance = Axlsx::Relationship.new(source_obj, Axlsx::WORKSHEET_R, 'target')

    assert_equal instance.Id, Axlsx::Relationship.new(source_obj, Axlsx::WORKSHEET_R, 'target').Id
  end

  def test_ids_cache_is_thread_safe
    cache1, cache2 = nil
    t1 = Thread.new { cache1 = Axlsx::Relationship.ids_cache }
    t2 = Thread.new { cache2 = Axlsx::Relationship.ids_cache }
    [t1, t2].each(&:join)

    refute_same(cache1, cache2)
  end

  def test_target_is_only_considered_for_same_attributes_check_if_target_mode_is_external
    source_obj = Object.new
    rel_1 = Axlsx::Relationship.new(source_obj, Axlsx::WORKSHEET_R, 'target')
    rel_2 = Axlsx::Relationship.new(source_obj, Axlsx::WORKSHEET_R, '../target')

    assert_equal rel_1.Id, rel_2.Id

    rel_3 = Axlsx::Relationship.new(source_obj, Axlsx::HYPERLINK_R, 'target', target_mode: :External)
    rel_4 = Axlsx::Relationship.new(source_obj, Axlsx::HYPERLINK_R, '../target', target_mode: :External)

    refute_equal rel_3.Id, rel_4.Id
  end

  def test_type
    assert_raises(ArgumentError) { Axlsx::Relationship.new nil, 'type', 'target' }
    refute_raises { Axlsx::Relationship.new nil, Axlsx::WORKSHEET_R, 'target' }
    refute_raises { Axlsx::Relationship.new nil, Axlsx::COMMENT_R, 'target' }
  end

  def test_target_mode
    assert_raises(ArgumentError) { Axlsx::Relationship.new nil, 'type', 'target', target_mode: "FISH" }
    refute_raises { Axlsx::Relationship.new(nil, Axlsx::WORKSHEET_R, 'target', target_mode: :External) }
  end

  def test_ampersand_escaping_in_target
    r = Axlsx::Relationship.new(nil, Axlsx::HYPERLINK_R, "http://example.com?foo=1&bar=2", target_mod: :External)
    doc = Nokogiri::XML(r.to_xml_string)

    assert_equal(1, doc.xpath("//Relationship[@Target='http://example.com?foo=1&bar=2']").size)
  end
end

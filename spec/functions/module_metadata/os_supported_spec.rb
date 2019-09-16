require 'spec_helper'

describe 'simplib::module_metadata::os_supported' do
  context 'on a supported OS' do
    facts = {
      :os => {
        'name' => 'Ubuntu',
        'release' => {
          'major' => '14',
          'full' => '14.04'
        }
      }
    }

    let(:facts) { facts }
    context 'with no version matching' do
      it { is_expected.to run.with_params('stdlib').and_return(true) }
    end

    context 'with full version matching' do
      it { is_expected.to run.with_params('stdlib', { 'os_validation' => { 'options' => { 'release_match' => 'full' } } } ).and_return(true) }
    end

    context 'with major version matching' do
      it { is_expected.to run.with_params('stdlib', { 'os_validation' => { 'options' => { 'release_match' => 'major' } } } ).and_return(true) }
    end
  end

  context 'on a supported, but blacklisted, OS' do
    facts = {
      :os => {
        'name' => 'Ubuntu',
        'release' => {
          'major' => '14',
          'full' => '14.999'
        }
      }
    }

    let(:facts) { facts }

    context 'with no version matching' do
      it { is_expected.to run.with_params('stdlib', { 'blacklist' => ['Ubuntu'] } ).and_return(false) }
    end

    context 'with full version matching' do
      it do
        is_expected.to run.with_params('stdlib',
          {
            'blacklist' => [{'Ubuntu' => '14.999'}],
            'blacklist_validation' => {
              'options' => {
                'release_match' => 'full'
              }
            }
          }
        ).and_return(false)
      end
    end

    context 'with major version matching' do
      it do
        is_expected.to run.with_params('stdlib',
          {
            'blacklist' => [{'Ubuntu' => '14.999'}],
            'blacklist_validation' => {
              'options' => {
                'release_match' => 'major'
              }
            }
          }
        ).and_return(false)
      end
    end

    context 'when disabled' do
      context 'globally' do
        it do
          is_expected.to run.with_params('stdlib',
            {
              'enable' => false,
              'blacklist' => [{'Ubuntu' => '14.999'}],
              'blacklist_validation' => {
                'options' => {
                  'release_match' => 'full'
                }
              }
            }
          ).and_return(true)
        end
      end

      context 'locally' do
        it do
          is_expected.to run.with_params('stdlib',
            {
              'blacklist' => [{'Ubuntu' => '14.999'}],
              'blacklist_validation' => {
                'enable' => false,
                'options' => {
                  'release_match' => 'full'
                }
              }
            }
          ).and_return(true)
        end
      end
    end
  end

  context 'on a supported OS with an unsupported full version' do
    facts = {
      :os => {
        'name' => 'Ubuntu',
        'release' => {
          'major' => '14',
          'full' => '14.999'
        }
      }
    }

    let(:facts) { facts }

    context 'with no version matching' do
      it { is_expected.to run.with_params('stdlib') }
    end

    context 'with full version matching' do
      it { is_expected.to run.with_params('stdlib', { 'os_validation' => { 'options' => { 'release_match' => 'full' } } } ).and_return(false) }
    end

    context 'when disabled' do
      context 'globally' do
        it { is_expected.to run.with_params('stdlib', { 'enable' => false, 'os_validation' => { 'options' => { 'release_match' => 'full' } } } ).and_return(true) }
      end

      context 'locally' do
        it { is_expected.to run.with_params('stdlib', { 'os_validation' => { 'enable' => false, 'options' => { 'release_match' => 'full' } } } ).and_return(true) }
      end
    end
  end

  context 'on a supported OS with an unsupported major version' do
    facts = {
      :os => {
        'name' => 'Ubuntu',
        'release' => {
          'major' => '1',
          'full' => '1.01'
        }
      }
    }

    let(:facts) { facts }

    context 'with no version matching' do
      it { is_expected.to run.with_params('stdlib') }
    end

    context 'with major version matching' do
      it { is_expected.to run.with_params('stdlib', { 'os_validation' => { 'options' => { 'release_match' => 'major' } } } ).and_return(false) }
    end
  end

  context 'on an unsupported OS' do
    facts = {
      :os => {
        'name' => 'Bob'
      }
    }

    let(:facts) { facts }

    context 'with no version matching' do
      it { is_expected.to run.with_params('stdlib').and_return(false) }
    end
  end
end
# vim: set expandtab ts=2 sw=2:

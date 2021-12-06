warn "Executing ewf_startup.pl...\n";
sleep 1;

# Extend @INC if needed

use lib qw(/home/ewf/MODULES /home/ewf/htdocs/efiling/handlers /home/ewf/config);

# Make sure we are in a sane environment.
$ENV{MOD_PERL} or die "not running under mod_perl!";

# Place common modules here to be pre-loaded by the mod_perl enabled server
use ModPerl::Registry;
use Socket;

### Recycle large Apache processes

use Apache2::SizeLimit;
$Apache2::SizeLimit::MAX_PROCESS_SIZE  = 90000; # 50MB
#$Apache2::SizeLimit::MIN_SHARE_SIZE    = 9000;  # 6MB
#$Apache2::SizeLimit::MAX_UNSHARED_SIZE = 5000;  # 5MB

$Apache2::SizeLimit::CHECK_EVERY_N_REQUESTS = 90;

# ----------------- MODULE --------------------
use CGI;
use CHData::CompanyPrefixes;
use CHDDB::chdCtrl;
use Common::AISHelper;
use Common::Basket;
use Common::CGIEngine;
use Common::ConstString;
use Common::CustomerHelper;
use Common::CVTable;
use Common::DateHelper;
use CommonDB::accountDetails;
use CommonDB::auth;
use CommonDB::customer;
use CommonDB::cvClass;
use CommonDB::cvClassCollection;
use CommonDB::CVConstants qw( :DEFAULT );
use CommonDB::cvRegistry;
use CommonDB::cvValue;
use CommonDB::document;
use CommonDB::DocumentSearch;
use CommonDB::emailNotify;
use CommonDB::GSession;
use CommonDB::GSessionAdmin;
use CommonDB::notification;
use CommonDB::OrderDetail;
use CommonDB::OrderHeader;
use CommonDB::OrderSearch;
use CommonDB::profileCollection;
use Common::goBackHelper;
use Common::Insolvency;
use Common::KeyGen;
use Common::navLink;
use Common::OrderHelper;
use Common::ScreenInfo;
use Common::URIHelper;
use Common::XMLMapper;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use File::Basename;
use File::Copy;
use HTML::Template;
use POSIX qw(strftime);
use Time::Local;
use Tuxedo::Error;
use Tuxedo::Service;
use XML::Simple;

use strict;
use CommonDB::GSession;
use CommonDB::cvRegistry;
use CommonDB::CVConstants qw( :CLASS :FORMTYPE );

use Framework::sessionException;
use Framework::exception;

use CompaniesHouse::Filing::UI::autoPage;

use CompaniesHouse::Filing::UI::Officers::Page::AP::appointNaturalDirectorPage;
use CompaniesHouse::Filing::UI::Officers::Page::AP::appointNaturalSecretaryPage;
use CompaniesHouse::Filing::UI::Officers::Page::AP::appointCorporateDirectorPage;
use CompaniesHouse::Filing::UI::Officers::Page::AP::appointCorporateSecretaryPage;
use CompaniesHouse::Filing::UI::Officers::Page::CH::changeNaturalDirectorPage;
use CompaniesHouse::Filing::UI::Officers::Page::CH::changeNaturalSecretaryPage;
use CompaniesHouse::Filing::UI::Officers::Page::CH::changeCorporateDirectorPage;
use CompaniesHouse::Filing::UI::Officers::Page::CH::changeCorporateSecretaryPage;
use CompaniesHouse::Filing::UI::Officers::Page::TM::terminateNaturalDirectorPage;
use CompaniesHouse::Filing::UI::Officers::Page::TM::terminateNaturalSecretaryPage;
use CompaniesHouse::Filing::UI::Officers::Page::TM::terminateCorporateDirectorPage;
use CompaniesHouse::Filing::UI::Officers::Page::TM::terminateCorporateSecretaryPage;

use CompaniesHouse::Filing::UI::Forms::JoinProofPage;
use CompaniesHouse::Filing::UI::Forms::LeaveProofPage;


#use CompaniesHouse::Filing::UI::AnnualReturn::Forms::TM01Confirm;
#use CompaniesHouse::Filing::UI::AnnualReturn::Forms::TM02Confirm;
use CompaniesHouse::Filing::UI::Forms::TM01Confirm;
use CompaniesHouse::Filing::UI::Forms::TM02Confirm;
use CompaniesHouse::Filing::UI::Forms::consentToActPage;
use CompaniesHouse::Filing::UI::Forms::intermediateChangePage;
use CompaniesHouse::Filing::UI::Forms::otherDirectorshipsPage;

use CompaniesHouse::Filing::UI::Forms::appointmentListPage;
use CompaniesHouse::Filing::UI::Forms::appointmentListTMPage;

use CompaniesHouse::Filing::UI::returnAllotmentSharesPage;

use CompaniesHouse::Filing::UI::StatementOfCapital::addStatementOfCapitalPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Capital::addStatementOfCapitalPageAR;
use CompaniesHouse::Filing::UI::AnnualReturn::Capital::issuedCapitalIncreasedWarning;
#use CompaniesHouse::Filing::UI::85ACT::AnnualReturn::Capital::issuedCapitalIncreasedWarning;
#use CompaniesHouse::Filing::UI::85ACT::AnnualReturn::Capital::addStatementOfCapitalPageAR;

#use CompaniesHouse::Filing::UI::allotmentPage;
#use CompaniesHouse::Filing::UI::addAllotmentPage;
use CompaniesHouse::Filing::UI::Allotment::addAllotmentPage;
use CompaniesHouse::Filing::UI::Allotment::amendAllotmentPage;
use CompaniesHouse::Filing::UI::Capital::addCapitalPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Capital::addCapitalPageAR;
#use CompaniesHouse::Filing::UI::85ACT::AnnualReturn::Capital::addCapitalPageAR;
use CompaniesHouse::Filing::UI::Capital::amendCapitalPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Capital::amendCapitalPageAR;
#use CompaniesHouse::Filing::UI::85ACT::AnnualReturn::Capital::amendCapitalPageAR;
use CompaniesHouse::Filing::UI::Forms::SAILPage;
use CompaniesHouse::Filing::UI::formState;
use CompaniesHouse::Filing::UI::Forms::registeredOfficeAddressPage;
use CompaniesHouse::Filing::UI::AnnualReturn::ARPage;
#use CompaniesHouse::Filing::UI::85ACT::AnnualReturn::ARPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::SAILPage;

#use CompaniesHouse::Filing::UI::85ACT::Forms::addNaturalAppointmentPage;
#use CompaniesHouse::Filing::UI::85ACT::Forms::addCorporateAppointmentPage;
#use CompaniesHouse::Filing::UI::85ACT::Forms::amendNaturalAppointmentPage;
#use CompaniesHouse::Filing::UI::85ACT::Forms::amendCorporateAppointmentPage;
#use CompaniesHouse::Filing::UI::85ACT::Forms::terminateNaturalAppointmentPage;
#use CompaniesHouse::Filing::UI::85ACT::Forms::terminateCorporateAppointmentPage;
#use CompaniesHouse::Filing::UI::85ACT::Forms::appointmentListPage;
#use CompaniesHouse::Filing::UI::85ACT::Forms::appointmentListTMPage;
#use CompaniesHouse::Filing::UI::85ACT::Forms::288bConfirm;


#  Action List display pages

use CompaniesHouse::Filing::UI::Appointment::showAppointmentsPage;
#use CompaniesHouse::Filing::UI::RegOffAddr::showRegisteredOfficeAddressPage;

  # Annual Return forms
  #
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::registeredOfficeAddressPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::appointNaturalDirectorPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::appointCorporateDirectorPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::appointNaturalSecretaryPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::appointCorporateSecretaryPage;

use CompaniesHouse::Filing::UI::AnnualReturn::Forms::changeNaturalDirectorPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::changeCorporateDirectorPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::changeNaturalSecretaryPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::changeCorporateSecretaryPage;

use CompaniesHouse::Filing::UI::AnnualReturn::Forms::terminateNaturalDirectorPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::terminateCorporateDirectorPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::terminateNaturalSecretaryPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::terminateCorporateSecretaryPage;

use CompaniesHouse::Filing::UI::AnnualReturn::Forms::TM01Confirm;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::TM02Confirm;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::consentToActPage;
use CompaniesHouse::Filing::UI::AnnualReturn::Forms::intermediateChangePage;

# 85 Act AR Forms
#
#use CompaniesHouse::Filing::UI::85ACT::AnnualReturn::Forms::membersAddressPage;
#use CompaniesHouse::Filing::UI::85ACT::AnnualReturn::Forms::debentureAddressPage;

use CompaniesHouse::Common::errorPage;
use CompaniesHouse::Common::httpPageScript;
use CompaniesHouse::Common::sessionManager;
use CompaniesHouse::Common::sessionErrorPage;

# Set some ENV variables for Perl
#
warn "Setting Orcale Environment Variables\n";
$ENV{ORACLE_HOME}="/usr/lib/oracle/11.2/client64/";
$ENV{LD_LIBRARY_PATH}="/usr/lib/oracle/11.2/client64/lib/";
$ENV{TNS_ADMIN}="/usr/lib/oracle/11.2/client64/lib/";

$ENV{NLS_LANG}   = "ENGLISH_UNITED KINGDOM.UTF8";
$ENV{LC_ALL}     = "en_GB.UTF-8";
$ENV{DBCONNECT_PING_RATE}=40;

warn "ewf_startup.pl - done\n";
1;

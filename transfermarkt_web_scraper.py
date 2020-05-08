import os
import requests
from bs4 import BeautifulSoup
from time import sleep

import pandas as pd


def get_clubs_and_transfers(league_name, league_id, season_id, window):
    headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36'}
    url = "https://www.transfermarkt.co.uk/{league_name}/transfers/wettbewerb/{league_id}/plus/?saison_id={season_id}&s_w={window}".format(league_name=league_name, league_id=league_id, season_id=season_id, window=window)
    try:
        response = requests.get(url, headers=headers)
        print("Connection successful, status code {}".format(response.status_code))
    except requests.exceptions.RequestException as e:
        print(e)
        exit()
    soup = BeautifulSoup(response.content, 'lxml')
    
    clubs = [tag.text for tag in soup.find_all('div', {'class': 'table-header'})][1:]
    
    tables = [tag.findChild() for tag in soup.find_all('div', {'class': 'responsive-table'})]
    table_in_list = tables[::2]
    table_out_list = tables[1::2]
    
    transfer_in_list = []
    transfer_out_list = []
    column_headers = {'season': season_id, 'window': window, 'league': league_name}
    for table_in, table_out in zip(table_in_list, table_out_list):
        transfer_in_list.append(get_transfer_info(table_in, movement='In', **column_headers))
        transfer_out_list.append(get_transfer_info(table_out, movement='Out', **column_headers))
    
    return clubs, transfer_in_list, transfer_out_list


def get_transfer_info(table, movement, season, window, league):
    transfer_info = []
    trs = table.find_all('tr')
    header_row = [header.get_text(strip=True) for header in trs[0].find_all('th')]
    if header_row:
        header_row[0] = 'Name'
        header_row.insert(0, 'Club')
        header_row[-2] = 'Club involved'
        header_row.insert(-1, 'Country involved')
        header_row += ['Movement', 'Season', 'Window', 'League']
        transfer_info.append(header_row)
    for tr in trs[1:]:
        row = []
        tds = tr.find_all('td')
        for td in tds:
            child = td.findChild()
            if child and child.get('class'):
                if child.get('class')[0] == 'di':
                    row.append(child.get_text(strip=True))
                elif child.get('class')[0] == 'flaggenrahmen':
                    row.append(child.get('alt'))
                elif child.get('class')[0] == 'vereinprofil_tooltip':
                    row.append(child.findChild().get('alt'))
            else:
                row.append(td.get_text(strip=True))
        if "No new arrivals" in row or "No departures" in row:
            transfer_info.append([None] * (len(header_row) - 1))
        else:
            row += [movement, season, window, league]
            transfer_info.append(row)
    
    return transfer_info


def formatted_transfers(clubs, transfers_in, transfers_out):
    for i in range(len(clubs)):
        club_name = clubs[i]
        for row in transfers_in[i][1:]:
            row.insert(0, club_name)
        for row in transfers_out[i][1:]:
            row.insert(0, club_name)
    
    return transfers_in, transfers_out


def transfers_dataframe(tables_list):
    return pd.concat([pd.DataFrame(table[1:], columns=table[0]) for table in tables_list])


def export_csv(df, season_id, league_name):
    file_name = '{}.csv'.format(league_name)
    path_name = './{}'.format(season_id)
    if not os.path.exists(path_name):
        os.mkdir(path_name)
    
    export_name = os.path.join(path_name, file_name)
    df.to_csv(export_name, index=False, encoding='utf-8')


def scrape_season_transfers(league_name, league_id, season_id, window):
    clubs, transfer_in_list, transfer_out_list = get_clubs_and_transfers(league_name, league_id, season_id, window)
    print("Got data for {} {} {} transfer window".format(season_id, league_name.upper(), window.upper()))
    transfers_in, transfers_out = formatted_transfers(clubs, transfer_in_list, transfer_out_list)
    print("Formatted transfers")
    df_in = transfers_dataframe(transfers_in)
    df_out = transfers_dataframe(transfers_out)
    print("Created dataframes")
    print("\n********************************\n")
    return pd.concat([df_in, df_out])


def main():
    league_names = ['premier-league']#, 'championship']
    league_ids = ['GB1']#, 'GB2']
    for league_name, league_id in zip(league_names, league_ids):
        for i in range(2018, 2019):
            league_transfers = []
            season_id = str(i)
            for window in ['s', 'w']:
                league_transfers.append(scrape_season_transfers(league_name, league_id, season_id, window))
                sleep(3)
            df = pd.concat(league_transfers)
            df = df[~df['Name'].isna()]
            df.reset_index(drop=True, inplace=True)
            export_csv(df, season_id, league_name)
    print("\n\nDone!")

if __name__ == "__main__":
    main()
